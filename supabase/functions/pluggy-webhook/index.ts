// Webhook da Pluggy: importa transações novas como lançamentos mesmo com o app
// fechado. Quem chama é a Pluggy (sem JWT), então o conteúdo do aviso NÃO é
// confiável: usamos só o itemId/accountId, conferimos o dono em pluggy_items e
// buscamos as transações na própria Pluggy. Um aviso forjado, no máximo,
// sincroniza dados legítimos do próprio dono do item.
// Como grava com service role (ignora o RLS), confere explicitamente se o dono
// tem acesso ativo (assinatura) antes da cota e da importação.
import { acessoAtivo, admin, consumirCota } from "../_shared/seguranca.ts";
import { pluggy } from "../_shared/pluggy.ts";

const EVENTOS = new Set(["transactions/created", "item/updated", "item/created"]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_PAGINAS = 20;
const CONECTOR_MEU_PLUGGY = 200;

type Conta = {
  id: string;
  itemId: string;
  type?: string;
  name?: string;
  taxNumber?: string;
  owner?: string;
};
type Parte = { name?: string; documentNumber?: { value?: string } | string };
type Transacao = {
  id: string;
  amount?: number;
  type?: string;
  description?: string;
  descriptionRaw?: string;
  date?: string;
  category?: string;
  paymentData?: { paymentMethod?: string; payer?: Parte; receiver?: Parte };
};

// Mesmas categorias neutras do app (lancamento.dart): não contam no saldo.
const TRANSFERENCIA_ENTRE_CONTAS = "Transferência entre contas";
const MOVIMENTACAO_INVESTIMENTO = "Investimento (aplicação/resgate)";
const RE_INVESTIMENTO =
  /\b(rdb|cdb|lci|lca|b3)\b|resgate|aplica[cç][aã]o|caixinha|cofrinho|porquinho|dinheiro guardado|dinheiro resgatado|nuinvest|tesouro|poupan[cç]a|nota bov|bovespa/;

const soDigitos = (s?: string) => (s ?? "").replace(/\D/g, "");
const nomeNormalizado = (s?: string) => (s ?? "").toLowerCase().replace(/\s+/g, " ").trim();

/** Mesma regra do app (categoriaNeutra em pluggy_open_finance_service.dart). */
function categoriaNeutra(tx: Transacao, descricao: string, entrada: boolean, conta: Conta) {
  const cat = (tx.category ?? "").toLowerCase();
  if (cat.includes("invest") || RE_INVESTIMENTO.test(descricao.toLowerCase())) {
    return MOVIMENTACAO_INVESTIMENTO;
  }
  if (
    cat.includes("same person") || cat.includes("same ownership") ||
    cat.includes("mesma titularidade")
  ) return TRANSFERENCIA_ENTRE_CONTAS;
  const nome = nomeNormalizado(conta.owner);
  // Alguns bancos só trazem a contraparte na descrição: "Transferência Recebida|NOME".
  const partes = descricao.split("|");
  if (nome && partes.length > 1 && nomeNormalizado(partes[partes.length - 1]) === nome) {
    return TRANSFERENCIA_ENTRE_CONTAS;
  }
  const parte = entrada ? tx.paymentData?.payer : tx.paymentData?.receiver;
  if (!parte) return null;
  const doc = soDigitos(
    typeof parte.documentNumber === "string" ? parte.documentNumber : parte.documentNumber?.value,
  );
  const cpf = soDigitos(conta.taxNumber);
  if (cpf.length === 11 && doc === cpf) return TRANSFERENCIA_ENTRE_CONTAS;
  if (!doc && nome && nomeNormalizado(parte.name) === nome) return TRANSFERENCIA_ENTRE_CONTAS;
  return null;
}

function ok(corpo: Record<string, unknown> = { ok: true }): Response {
  return new Response(JSON.stringify(corpo), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

/** Data no fuso de Brasília (a Pluggy manda em UTC). */
function dataLocal(iso?: string): string {
  const d = iso ? new Date(iso) : new Date();
  return new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo" })
    .format(isNaN(d.getTime()) ? new Date() : d);
}

// Mesmo mapeamento do app (PluggyOpenFinanceService._mapearCategoria).
function categoria(catPluggy: string | undefined, descricao: string): string {
  const cat = (catPluggy ?? "").toLowerCase();
  const tem = (s: string, ...xs: string[]) => xs.some((x) => s.includes(x));
  if (cat) {
    if (tem(cat, "food", "restauran", "refeição", "alimenta")) return "Alimentação";
    if (tem(cat, "transport", "gas", "combust", "uber")) return "Transporte";
    if (tem(cat, "health", "saude", "saúde", "pharmacy", "farm")) return "Saúde";
    if (tem(cat, "entertainment", "lazer", "stream", "cinema")) return "Lazer";
    if (tem(cat, "shopping", "compra", "loja")) return "Compras";
    if (tem(cat, "educat", "educa")) return "Educação";
    if (tem(cat, "home", "moradia", "aluguel", "luz", "água")) return "Moradia";
  }
  const d = descricao.toLowerCase();
  if (tem(d, "ifood", "mercado", "supermercado", "restaurante", "padaria")) {
    return "Alimentação";
  }
  if (tem(d, "uber", "99", "posto", "gasolina")) return "Transporte";
  if (tem(d, "farmacia", "drogaria", "hospital")) return "Saúde";
  return "Outros";
}

// Mesma regra do app (ehPagamentoDeFatura): o pagamento da fatura sai da
// conta e entra no cartão, mas as compras já vêm pelo cartão.
function ehPagamentoDeFatura(categoria: string | undefined, descricao: string): boolean {
  const cat = (categoria ?? "").toLowerCase();
  if (
    cat.includes("credit card payment") || cat.includes("pagamento de cartão") ||
    cat.includes("pagamento de fatura")
  ) return true;
  return /pagamento (de |da )?fatura|pagto\.? fatura|pagamento recebido|pagamento efetuado|pgto fatura/
    .test(descricao.toLowerCase());
}

async function contasDoItem(itemId: string, accountId?: string): Promise<Conta[]> {
  if (accountId) {
    const r = await pluggy("GET", `/accounts/${encodeURIComponent(accountId)}`);
    if (!r.ok) return [];
    const conta = await r.json() as Conta;
    return conta.itemId === itemId ? [conta] : [];
  }
  const r = await pluggy("GET", `/accounts?itemId=${encodeURIComponent(itemId)}`);
  if (!r.ok) return [];
  return ((await r.json()).results ?? []) as Conta[];
}

async function transacoes(
  accountId: string,
  filtro: Record<string, string>,
): Promise<Transacao[]> {
  const todas: Transacao[] = [];
  let params = new URLSearchParams({ accountId, ...filtro });
  for (let i = 0; i < MAX_PAGINAS; i++) {
    const r = await pluggy("GET", `/v2/transactions?${params}`);
    if (!r.ok) {
      console.warn(JSON.stringify({ rota: "/v2/transactions", status: r.status }));
      break;
    }
    const { results, next } = await r.json();
    todas.push(...(results ?? []));
    if (!next) break;
    params = new URLSearchParams(String(next).replace(/^\?/, ""));
    if (!params.get("accountId")) params.set("accountId", accountId);
  }
  return todas;
}

async function importar(
  userId: string,
  itemId: string,
  evento: Record<string, unknown>,
): Promise<void> {
  const itemResp = await pluggy("GET", `/items/${encodeURIComponent(itemId)}`);
  const item = itemResp.ok ? await itemResp.json() : {};
  const nomeConector: string = item?.connector?.name ?? "Banco";
  const ehMeuPluggy = item?.connector?.id === CONECTOR_MEU_PLUGGY;

  const desde = typeof evento.transactionsCreatedAtFrom === "string"
    ? { createdAtFrom: evento.transactionsCreatedAtFrom }
    : { dateFrom: dataLocal(new Date(Date.now() - 7 * 864e5).toISOString()) };
  const accountId = typeof evento.accountId === "string" && UUID.test(evento.accountId)
    ? evento.accountId
    : undefined;

  let novas = 0;
  for (const conta of await contasDoItem(itemId, accountId)) {
    const credito = (conta.type ?? "").toUpperCase() === "CREDIT";
    const nomeBanco = ehMeuPluggy && conta.name?.trim() ? conta.name.trim() : nomeConector;
    for (const tx of await transacoes(conta.id, desde)) {
      const valor = Math.round(Math.abs(tx.amount ?? 0) * 100);
      if (!tx.id || valor === 0) continue;
      const descricao = (tx.description ?? tx.descriptionRaw ?? `Transação ${nomeBanco}`)
        .trim().slice(0, 200) || `Transação ${nomeBanco}`;
      if (ehPagamentoDeFatura(tx.category, descricao)) continue;
      const pix = (tx.paymentData?.paymentMethod ?? "").toUpperCase() === "PIX" ||
        descricao.toLowerCase().includes("pix");
      // No cartão de crédito o sinal é invertido: positivo = compra (saída).
      const entrada = credito ? (tx.amount ?? 0) < 0 : (tx.amount ?? 0) > 0;
      const { error } = await admin.from("lancamentos").insert({
        user_id: userId,
        descricao,
        valor_cents: valor,
        categoria: categoriaNeutra(tx, descricao, entrada, conta) ??
          categoria(tx.category, descricao),
        forma_pagamento: pix ? "Pix" : credito ? `Cartão: ${nomeBanco}` : `Conta: ${nomeBanco}`,
        data: dataLocal(tx.date),
        tipo: entrada ? "receita" : "despesa",
        obs: `pluggy_id:${tx.id}`,
      });
      if (!error) novas++;
      // 23505 = já importada (índice único user_id+obs): ignorar.
      else if (error.code !== "23505") {
        console.warn(JSON.stringify({ erro: "insert_lancamento", codigo: error.code }));
      }
    }
  }
  // Diagnóstico sem dados financeiros.
  console.log(JSON.stringify({ evento: evento.event, novas }));
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });
  let evento: Record<string, unknown>;
  try {
    evento = await req.json();
  } catch {
    return new Response(null, { status: 400 });
  }

  // Respostas 200 para avisos ignorados: evita que a Pluggy fique reenviando.
  const itemId = evento?.itemId;
  if (
    typeof evento?.event !== "string" || !EVENTOS.has(evento.event) ||
    typeof itemId !== "string" || !UUID.test(itemId)
  ) {
    return ok({ ignorado: true });
  }

  const { data: dono } = await admin
    .from("pluggy_items")
    .select("user_id")
    .eq("item_id", itemId)
    .maybeSingle();
  if (!dono) return ok({ ignorado: true });

  // Dono sem acesso ativo: ignora (o app importa de novo quando a conta voltar).
  try {
    const { data, error } = await admin.auth.admin.getUserById(dono.user_id);
    if (error) throw error;
    if (!(await acessoAtivo(dono.user_id, data.user?.email))) {
      console.log(JSON.stringify({ evento: evento.event, ignorado: "acesso_inativo" }));
      return ok({ ignorado: true });
    }
  } catch {
    console.warn(JSON.stringify({ erro: "verificar_acesso" }));
    return ok({ ignorado: true });
  }
  if (!(await consumirCota(dono.user_id, "webhook", 300))) return ok({ ignorado: true });

  // A Pluggy espera resposta rápida: importa em segundo plano.
  EdgeRuntime.waitUntil(
    importar(dono.user_id, itemId, evento).catch((e) =>
      console.warn(JSON.stringify({ erro: "importar", tipo: e?.name }))
    ),
  );
  return ok();
});
