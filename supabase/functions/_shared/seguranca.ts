// Utilitários comuns às Edge Functions: autenticação, cota diária e CORS.
import { createClient, type User } from "npm:@supabase/supabase-js@2";

export const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const ORIGENS_PADRAO = ["https://leonardorsvieira.github.io"];

function origemPermitida(origem: string | null): string | null {
  if (!origem) return null;
  const extras = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);
  if ([...ORIGENS_PADRAO, ...extras].includes(origem)) return origem;
  // Desenvolvimento local (flutter run -d chrome usa porta aleatória).
  if (/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origem)) return origem;
  return null;
}

export function cabecalhosCors(req: Request): Record<string, string> {
  const origem = origemPermitida(req.headers.get("Origin"));
  return {
    ...(origem ? { "Access-Control-Allow-Origin": origem } : {}),
    "Vary": "Origin",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

export function resposta(
  req: Request,
  status: number,
  corpo: unknown,
): Response {
  return new Response(
    typeof corpo === "string" ? corpo : JSON.stringify(corpo),
    {
      status,
      headers: { ...cabecalhosCors(req), "Content-Type": "application/json" },
    },
  );
}

/** Usuário do JWT, somente se o e-mail estiver confirmado. */
export async function usuarioAutenticado(req: Request): Promise<User | null> {
  const auth = req.headers.get("Authorization") ?? "";
  const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!jwt) return null;
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) return null;
  if (!data.user.email_confirmed_at) return null;
  return data.user;
}

/** Registra uma chamada e devolve false se o limite diário foi excedido. */
export async function consumirCota(
  userId: string,
  recurso: string,
  limitePadrao: number,
): Promise<boolean> {
  const limite = Number(
    Deno.env.get(`LIMITE_DIARIO_${recurso.toUpperCase()}`) ?? limitePadrao,
  );
  const { data, error } = await admin.rpc("consumir_cota", {
    p_user: userId,
    p_recurso: recurso,
    p_limite: limite,
  });
  if (error) throw error;
  return data === true;
}

/** Data de hoje no fuso de Brasília, no formato aaaa-MM-dd. */
export function hojeEmBrasilia(): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo" })
    .format(new Date());
}

/**
 * A conta tem acesso ativo? Administrador, ou e-mail em `acessos` sem prazo ou
 * com validade em dia. Mesma regra de public.acesso_ativo() (migration
 * 20261001220000_controle_de_acesso.sql) — mude as duas juntas. Usa o cliente
 * service role (ignora o RLS), então quem chama decide o que fazer com o erro.
 */
export async function acessoAtivo(
  userId: string,
  email: string | null | undefined,
): Promise<boolean> {
  const { data: adm, error: erroAdm } = await admin
    .from("administradores")
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (erroAdm) throw erroAdm;
  if (adm) return true;

  const emailNormalizado = (email ?? "").trim().toLowerCase();
  if (!emailNormalizado) return false;

  const { data: linha, error } = await admin
    .from("acessos")
    .select("valido_ate")
    .eq("email", emailNormalizado)
    .maybeSingle();
  if (error) throw error;
  if (!linha) return false;
  if (linha.valido_ate === null) return true;
  // 'aaaa-MM-dd' compara certo como texto.
  return String(linha.valido_ate) >= hojeEmBrasilia();
}

/**
 * Preâmbulo comum: CORS preflight, método, autenticação, acesso ativo e cota.
 * Devolve o usuário ou a Response de erro a ser retornada.
 */
export async function preambulo(
  req: Request,
  recurso: string,
  limitePadrao: number,
): Promise<User | Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cabecalhosCors(req) });
  }
  if (req.method !== "POST") {
    return resposta(req, 405, { erro: "metodo_nao_permitido" });
  }
  const usuario = await usuarioAutenticado(req);
  if (!usuario) return resposta(req, 401, { erro: "nao_autenticado" });
  // Conta sem acesso ativo não gasta cota nem chega ao Gemini/Pluggy.
  let ativo: boolean;
  try {
    ativo = await acessoAtivo(usuario.id, usuario.email);
  } catch (e) {
    console.error(JSON.stringify({
      etapa: "verificar_acesso",
      erro: (e as { message?: string } | null)?.message ?? String(e),
    }));
    return resposta(req, 503, { erro: "verificacao_acesso_falhou" });
  }
  if (!ativo) return resposta(req, 403, { erro: "acesso_inativo" });
  if (!(await consumirCota(usuario.id, recurso, limitePadrao))) {
    return resposta(req, 429, { erro: "limite_diario" });
  }
  return usuario;
}
