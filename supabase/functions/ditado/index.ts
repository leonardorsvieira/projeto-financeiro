// Proxy autenticado para o Gemini (generateContent). A GEMINI_API_KEY fica só aqui,
// como secret do Supabase — nunca no app (o bundle web é público).
import {
  admin,
  consumirCota,
  preambulo,
  resposta,
} from "../_shared/seguranca.ts";

// Os modelos 2.x não servem mais: o Google restringiu o 2.5 a quem já o
// usava (404 para esta chave) e o 2.0/1.5 saíram do ar.
const MODELOS_PERMITIDOS = new Set([
  "gemini-3.5-flash-lite",
  "gemini-3.5-flash",
  "gemini-3.1-flash-lite",
]);

// Única ferramenta aceita: a Busca Google do Guia de investimentos. Execução
// de código, leitura de URL etc. são recusadas.
const FERRAMENTAS_PERMITIDAS = new Set(["google_search"]);

// A Busca Google não existe no plano gratuito do Gemini para os modelos 3.x
// (responde 429 na hora). Ela só vai ao Gemini com o segredo BUSCA_GOOGLE=1,
// que só faz sentido com faturamento ativo. Desligada, o pedido do guia segue
// sem a ferramenta, com os indicadores do Banco Central que o app manda.
function buscaGoogleLigada(): boolean {
  return Deno.env.get("BUSCA_GOOGLE") === "1";
}

// O pedido do guia (o que traz `tools`) tem cota diária própria. Ela é
// conferida antes e consumida só quando o Gemini responde: tentativa que
// falhou não gasta.
const RECURSO_GUIA = "consultoria";
const LIMITE_PADRAO_GUIA = 10;

// Áudio em base64 + prompt; ditados reais ficam bem abaixo disso.
const TAMANHO_MAXIMO = 10 * 1024 * 1024;

// Sem limite, uma resposta lenta do Gemini prendia a função até ela ser
// encerrada e o app ficava "processando" para sempre. O guia é um texto longo
// (e, com busca, o Gemini pesquisa antes): precisa de mais tempo.
const TEMPO_MAXIMO_GEMINI_MS = 40_000;
const TEMPO_MAXIMO_GUIA_MS = 80_000;

function ferramentasPermitidas(ferramentas: unknown): boolean {
  if (!Array.isArray(ferramentas) || ferramentas.length === 0) return false;
  return ferramentas.every((f) => {
    if (typeof f !== "object" || f === null || Array.isArray(f)) return false;
    const chaves = Object.keys(f);
    return chaves.length === 1 && FERRAMENTAS_PERMITIDAS.has(chaves[0]);
  });
}

function limiteGuia(): number {
  return Number(
    Deno.env.get(`LIMITE_DIARIO_${RECURSO_GUIA.toUpperCase()}`) ??
      LIMITE_PADRAO_GUIA,
  );
}

/** Ainda há cota do guia hoje? `uso_diario.dia` é o current_date (UTC). */
async function guiaDisponivel(userId: string): Promise<boolean> {
  const { data, error } = await admin
    .from("uso_diario")
    .select("chamadas")
    .eq("user_id", userId)
    .eq("recurso", RECURSO_GUIA)
    .eq("dia", new Date().toISOString().slice(0, 10))
    .maybeSingle();
  if (error) throw error;
  return (data?.chamadas ?? 0) < limiteGuia();
}

Deno.serve(async (req) => {
  const usuario = await preambulo(req, "ditado", 150);
  if (usuario instanceof Response) return usuario;

  const chave = Deno.env.get("GEMINI_API_KEY");
  if (!chave) return resposta(req, 503, { erro: "ia_nao_configurada" });

  const texto = await req.text();
  console.log(JSON.stringify({ etapa: "corpo_recebido", bytes: texto.length }));
  if (texto.length > TAMANHO_MAXIMO) {
    return resposta(req, 413, { erro: "requisicao_grande_demais" });
  }

  let modelo: unknown;
  let corpo: unknown;
  try {
    ({ modelo, corpo } = JSON.parse(texto));
  } catch {
    return resposta(req, 400, { erro: "json_invalido" });
  }
  if (typeof modelo !== "string" || !MODELOS_PERMITIDOS.has(modelo)) {
    return resposta(req, 400, { erro: "modelo_nao_permitido" });
  }
  if (typeof corpo !== "object" || corpo === null) {
    return resposta(req, 400, { erro: "corpo_invalido" });
  }

  const pedido = corpo as Record<string, unknown>;
  const ferramentas = pedido.tools;
  const ehGuia = ferramentas !== undefined;
  const comBusca = ehGuia && buscaGoogleLigada();
  if (ehGuia) {
    if (!ferramentasPermitidas(ferramentas)) {
      return resposta(req, 400, { erro: "ferramenta_nao_permitida" });
    }
    let disponivel: boolean;
    try {
      disponivel = await guiaDisponivel(usuario.id);
    } catch (e) {
      console.error(JSON.stringify({
        etapa: "verificar_cota_guia",
        erro: (e as { message?: string } | null)?.message ?? String(e),
      }));
      return resposta(req, 503, { erro: "verificacao_cota_falhou" });
    }
    if (!disponivel) {
      return resposta(req, 429, { erro: "limite_diario_consultoria" });
    }
    if (!comBusca) delete pedido.tools;
  }

  // Diagnóstico sem conteúdo do ditado: só tamanho, modelo, status e tempo.
  const inicio = Date.now();
  let r: Response;
  try {
    r = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": chave },
        body: JSON.stringify(pedido),
        signal: AbortSignal.timeout(
          ehGuia ? TEMPO_MAXIMO_GUIA_MS : TEMPO_MAXIMO_GEMINI_MS,
        ),
      },
    );
  } catch (e) {
    console.warn(JSON.stringify({
      modelo,
      bytes: texto.length,
      guia: ehGuia,
      busca: comBusca,
      erro: e instanceof Error ? e.name : "desconhecido",
      ms: Date.now() - inicio,
    }));
    // 504 é tratado pelo app como temporário (tenta de novo / outro modelo).
    return resposta(req, 504, { erro: "ia_sem_resposta" });
  }
  if (ehGuia && r.ok) {
    try {
      await consumirCota(usuario.id, RECURSO_GUIA, LIMITE_PADRAO_GUIA);
    } catch (e) {
      // A resposta já foi gerada: entrega mesmo sem conseguir registrar.
      console.error(JSON.stringify({
        etapa: "consumir_cota_guia",
        erro: (e as { message?: string } | null)?.message ?? String(e),
      }));
    }
  }
  const saida = await r.text();
  let motivo: unknown;
  let mensagem: unknown;
  if (!r.ok) {
    try {
      const erro = JSON.parse(saida)?.error;
      motivo = erro?.status;
      // A mensagem de erro do Google (cota, modelo) não traz o conteúdo do
      // pedido; ajuda a diagnosticar 429/404.
      mensagem = typeof erro?.message === "string"
        ? erro.message.slice(0, 300)
        : undefined;
    } catch {
      // corpo não-JSON
    }
  }
  console.log(JSON.stringify({
    modelo,
    bytes: texto.length,
    guia: ehGuia,
    busca: comBusca,
    status: r.status,
    motivo,
    mensagem,
    ms: Date.now() - inicio,
  }));
  return resposta(req, r.status, saida);
});
