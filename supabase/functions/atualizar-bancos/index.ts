// Pede à Pluggy uma sincronização nova das conexões de quem tem acesso ativo.
//
// Chamada pelo pg_cron às 8h, 14h e 20h de Brasília (migration
// *_atualizacao_automatica_bancos.sql) com o segredo do Vault no cabeçalho
// `x-cron-secret` — o segredo é gerado no banco e conferido por RPC, nunca
// sai dele. Quando cada sincronização termina, a Pluggy avisa o
// `pluggy-webhook` (item/updated), que importa as transações; o app lê o
// saldo novo ao abrir.
import { acessoAtivo, admin } from "../_shared/seguranca.ts";
import { pluggy } from "../_shared/pluggy.ts";

declare const EdgeRuntime: { waitUntil(promessa: Promise<unknown>): void };

const LOTE = 5;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// Conexões que dependem do usuário (senha/MFA): pedir de novo só falha.
const PRECISA_USUARIO = new Set(["LOGIN_ERROR", "WAITING_USER_INPUT"]);
// Meu Pluggy: a Pluggy recusa o PATCH (400 "MeuPluggy item cant be
// updated") — ela mesma sincroniza essas conexões, uma vez por dia.
const CONECTOR_MEU_PLUGGY = 200;

/** Pede a sincronização de um item; devolve o resultado para o log. */
async function atualizarItem(itemId: string): Promise<string> {
  const atual = await pluggy("GET", `/items/${encodeURIComponent(itemId)}`);
  if (!atual.ok) return `item_${atual.status}`;
  const item = await atual.json();
  if (item.connector?.id === CONECTOR_MEU_PLUGGY) return "meu_pluggy";
  if (PRECISA_USUARIO.has(item.status)) return "precisa_usuario";
  if (item.status === "UPDATING") return "ja_atualizando";
  // Sem credenciais: a Pluggy usa as guardadas.
  const r = await pluggy("PATCH", `/items/${encodeURIComponent(itemId)}`, {});
  if (r.ok) return "pedido";
  let codigo = "";
  try {
    const erro = await r.json();
    codigo = String(erro?.codeDescription ?? erro?.code ?? "");
    // Mensagem da Pluggy (sem dados financeiros), cortada.
    console.warn(JSON.stringify({
      rota: "PATCH /items/:id",
      status: r.status,
      conector: item.connector?.id,
      mensagem: String(erro?.message ?? "").slice(0, 200),
    }));
  } catch {
    // corpo não-JSON
  }
  return `patch_${r.status}${codigo ? `_${codigo}` : ""}`;
}

async function atualizarTodos(somenteUsuario?: string): Promise<void> {
  let consulta = admin.from("pluggy_items").select("item_id, user_id");
  if (somenteUsuario) consulta = consulta.eq("user_id", somenteUsuario);
  const { data, error } = await consulta;
  if (error) throw error;

  const porUsuario = new Map<string, string[]>();
  for (const { item_id, user_id } of data ?? []) {
    porUsuario.set(user_id, [...(porUsuario.get(user_id) ?? []), item_id]);
  }

  // Só quem tem acesso ativo (assinatura em dia ou administrador).
  const itens: string[] = [];
  let semAcesso = 0;
  for (const [userId, ids] of porUsuario) {
    try {
      const { data: u, error: e } = await admin.auth.admin.getUserById(userId);
      if (e || !u.user || !(await acessoAtivo(userId, u.user.email))) {
        semAcesso += ids.length;
        continue;
      }
      itens.push(...ids);
    } catch {
      semAcesso += ids.length;
    }
  }

  const resultados: Record<string, number> = {};
  for (let i = 0; i < itens.length; i += LOTE) {
    const lote = await Promise.allSettled(
      itens.slice(i, i + LOTE).map(atualizarItem),
    );
    for (const r of lote) {
      const chave = r.status === "fulfilled" ? r.value : "erro";
      resultados[chave] = (resultados[chave] ?? 0) + 1;
    }
  }
  // Diagnóstico sem dados financeiros nem identificadores.
  console.log(JSON.stringify({
    atualizar_bancos: {
      usuarios: porUsuario.size,
      conexoes: itens.length,
      sem_acesso: semAcesso,
      resultados,
    },
  }));
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });

  const segredo = req.headers.get("x-cron-secret") ?? "";
  if (segredo.length < 32) return new Response(null, { status: 401 });
  const { data: confere } = await admin.rpc("cron_atualizar_bancos_confere", {
    segredo,
  });
  if (confere !== true) return new Response(null, { status: 401 });

  // Teste manual: só as conexões de um usuário.
  let somenteUsuario: string | undefined;
  try {
    const corpo = await req.json();
    if (
      typeof corpo?.somente_usuario === "string" &&
      UUID.test(corpo.somente_usuario)
    ) {
      somenteUsuario = corpo.somente_usuario;
    }
  } catch {
    // corpo vazio
  }

  // Responde já (o pg_net não espera) e trabalha em segundo plano.
  EdgeRuntime.waitUntil(
    atualizarTodos(somenteUsuario).catch((e) =>
      console.warn(JSON.stringify({
        erro: "atualizar_bancos",
        mensagem: String(e).slice(0, 200),
      }))
    ),
  );
  return new Response(JSON.stringify({ ok: true }), {
    status: 202,
    headers: { "Content-Type": "application/json" },
  });
});
