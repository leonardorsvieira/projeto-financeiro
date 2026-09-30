// Proxy autenticado para a API da Pluggy.
//
// A conta Pluggy (client id/secret) é compartilhada por todos os usuários do app,
// então este proxy é quem garante o isolamento: cada item (conexão bancária) tem
// dono em `public.pluggy_items`, e só rotas de uma allowlist são repassadas —
// sempre verificando que o item/conta pertence ao usuário do JWT.
import { admin, preambulo, resposta } from "../_shared/seguranca.ts";
import { apiKey, pluggy, PLUGGY } from "../_shared/pluggy.ts";

// Cada conexão nasce com o webhook que importa transações com o app fechado
// (a Pluggy não tem cadastro de webhook no painel, só via API/parâmetro).
const WEBHOOK_URL = `${Deno.env.get("SUPABASE_URL")}/functions/v1/pluggy-webhook`;

async function ehDono(userId: string, itemId: string): Promise<boolean> {
  const { data } = await admin
    .from("pluggy_items")
    .select("user_id")
    .eq("item_id", itemId)
    .maybeSingle();
  return data?.user_id === userId;
}

/** Registra o item para o usuário; false se já pertence a outra pessoa. */
async function registrar(userId: string, itemId: string): Promise<boolean> {
  await admin
    .from("pluggy_items")
    .upsert({ item_id: itemId, user_id: userId }, {
      onConflict: "item_id",
      ignoreDuplicates: true,
    });
  return ehDono(userId, itemId);
}

/**
 * Um item ainda não registrado só pode ser reivindicado por quem o criou
 * (clientUserId definido por este proxy). Items antigos, criados antes do proxy
 * e sem clientUserId, só podem ser reivindicados pelo OWNER_USER_ID.
 */
async function podeAcessarItem(userId: string, itemId: string): Promise<boolean> {
  if (await ehDono(userId, itemId)) return true;
  const r = await pluggy("GET", `/items/${encodeURIComponent(itemId)}`);
  if (!r.ok) return false;
  const item = await r.json();
  const legado = !item.clientUserId && userId === Deno.env.get("OWNER_USER_ID");
  if (item.clientUserId !== userId && !legado) return false;
  return registrar(userId, itemId);
}

async function itemDaConta(accountId: string): Promise<string | null> {
  const r = await pluggy("GET", `/accounts/${encodeURIComponent(accountId)}`);
  if (!r.ok) return null;
  const conta = await r.json();
  return typeof conta.itemId === "string" ? conta.itemId : null;
}

/** Log de diagnóstico sem dados financeiros: só rota e status. */
function registrarFalha(rota: string, status: number) {
  console.warn(JSON.stringify({ rota, status }));
}

function repassar(req: Request, r: Response, texto: string): Response {
  if (!r.ok) {
    const url = new URL(r.url);
    let codigo: unknown;
    try {
      codigo = JSON.parse(texto)?.code;
    } catch {
      // corpo não-JSON
    }
    console.warn(JSON.stringify({
      rota: url.pathname.split("/").slice(0, 3).join("/"),
      status: r.status,
      codigo,
    }));
  }
  return resposta(req, r.status, texto);
}

async function atender(req: Request): Promise<Response> {
  const usuario = await preambulo(req, "pluggy", 3000);
  if (usuario instanceof Response) return usuario;
  const uid = usuario.id;

  let metodo: string;
  let caminho: string;
  let corpo: Record<string, unknown> | undefined;
  try {
    ({ metodo, caminho, corpo } = await req.json());
  } catch {
    return resposta(req, 400, { erro: "json_invalido" });
  }
  if (typeof metodo !== "string" || typeof caminho !== "string") {
    return resposta(req, 400, { erro: "requisicao_invalida" });
  }

  // Normaliza e impede qualquer destino que não seja a própria API da Pluggy.
  const url = new URL(caminho, PLUGGY);
  if (url.origin !== PLUGGY) return resposta(req, 400, { erro: "destino_invalido" });
  const seg = url.pathname.split("/").filter(Boolean);
  const q = url.searchParams;

  if (metodo === "GET" && seg[0] === "status" && seg.length === 1) {
    const configurado = !!Deno.env.get("PLUGGY_CLIENT_ID") &&
      !!Deno.env.get("PLUGGY_CLIENT_SECRET");
    return resposta(req, 200, { configurado });
  }

  try {
    if (!(await apiKey())) {
      return resposta(req, 503, { erro: "pluggy_nao_configurada" });
    }
  } catch {
    return resposta(req, 502, { erro: "pluggy_auth_falhou" });
  }

  // Catálogo público de conectores (bancos).
  if (metodo === "GET" && seg[0] === "connectors") {
    const r = await pluggy("GET", url.pathname + url.search);
    return repassar(req, r, await r.text());
  }

  // Connect Token: sempre amarrado ao usuário via clientUserId.
  if (metodo === "POST" && seg[0] === "connect_token" && seg.length === 1) {
    const opcoesCliente = (corpo?.options ?? {}) as Record<string, unknown>;
    const options: Record<string, unknown> = {
      clientUserId: uid,
      webhookUrl: WEBHOOK_URL,
    };
    if (typeof opcoesCliente.connectorId === "number") {
      options.connectorId = opcoesCliente.connectorId;
    }
    if (typeof opcoesCliente.oauthRedirectUri === "string") {
      options.oauthRedirectUri = opcoesCliente.oauthRedirectUri;
    }
    const body: Record<string, unknown> = { options };
    if (typeof corpo?.itemId === "string") {
      if (!(await ehDono(uid, corpo.itemId))) {
        return resposta(req, 404, { erro: "item_nao_encontrado" });
      }
      body.itemId = corpo.itemId;
    }
    const r = await pluggy("POST", "/connect_token", body);
    return repassar(req, r, await r.text());
  }

  // Criação direta de item (ex.: Meu Pluggy via OAuth).
  if (metodo === "POST" && seg[0] === "items" && seg.length === 1) {
    if (typeof corpo?.connectorId !== "number") {
      return resposta(req, 400, { erro: "connector_invalido" });
    }
    const r = await pluggy("POST", "/items", {
      connectorId: corpo.connectorId,
      parameters: corpo.parameters ?? {},
      clientUserId: uid,
      webhookUrl: WEBHOOK_URL,
    });
    const texto = await r.text();
    if (r.ok) {
      const item = JSON.parse(texto);
      if (typeof item.id === "string") await registrar(uid, item.id);
    }
    return repassar(req, r, texto);
  }

  // Remove TODAS as conexões do próprio usuário (na Pluggy e no registro).
  if (metodo === "DELETE" && seg[0] === "items" && seg.length === 1) {
    const { data } = await admin
      .from("pluggy_items")
      .select("item_id")
      .eq("user_id", uid);
    let removidas = 0;
    for (const { item_id } of data ?? []) {
      const r = await pluggy("DELETE", `/items/${encodeURIComponent(item_id)}`);
      // 404: já não existe na Pluggy; só falta limpar o registro.
      if (r.ok || r.status === 404) {
        await admin.from("pluggy_items").delete()
          .eq("item_id", item_id).eq("user_id", uid);
        removidas++;
      } else {
        registrarFalha("DELETE /items/:id", r.status);
      }
    }
    return resposta(req, 200, { removidas, total: data?.length ?? 0 });
  }

  // Lista apenas os items do próprio usuário.
  if (metodo === "GET" && seg[0] === "items" && seg.length === 1) {
    // Items criados pelo widget Connect vêm com clientUserId = usuário, mas o
    // app não recebe o id deles; registra aqui os que forem deste usuário.
    // (Items antigos sem clientUserId NÃO são reivindicados em massa: podem
    // ser de outros clientes. Só via id explícito + OWNER_USER_ID.)
    const lista = await pluggy("GET", "/items");
    if (lista.ok) {
      const { results: todos } = await lista.json();
      for (const item of todos ?? []) {
        if (item?.clientUserId === uid && typeof item.id === "string") {
          await registrar(uid, item.id);
        }
      }
    } else {
      registrarFalha("GET /items (listagem)", lista.status);
    }
    const { data } = await admin
      .from("pluggy_items")
      .select("item_id")
      .eq("user_id", uid);
    const results = [];
    for (const { item_id } of data ?? []) {
      const r = await pluggy("GET", `/items/${encodeURIComponent(item_id)}`);
      if (r.ok) results.push(await r.json());
    }
    // Diagnóstico sem dados financeiros: situação de cada conexão.
    console.log(JSON.stringify({
      itens: results.map((i) => ({
        status: i.status,
        execucao: i.executionStatus,
        conector: i.connector?.id,
        webhook: i.webhookUrl === WEBHOOK_URL,
      })),
    }));
    return resposta(req, 200, { results });
  }

  if (seg[0] === "items" && seg.length === 2) {
    let itemId: string;
    try {
      itemId = decodeURIComponent(seg[1]);
    } catch {
      return resposta(req, 400, { erro: "item_invalido" });
    }
    if (!(await podeAcessarItem(uid, itemId))) {
      return resposta(req, 404, { erro: "item_nao_encontrado" });
    }
    if (metodo === "GET") {
      const r = await pluggy("GET", `/items/${encodeURIComponent(itemId)}`);
      return repassar(req, r, await r.text());
    }
    if (metodo === "DELETE") {
      const r = await pluggy("DELETE", `/items/${encodeURIComponent(itemId)}`);
      if (r.ok || r.status === 404) {
        await admin.from("pluggy_items").delete()
          .eq("item_id", itemId).eq("user_id", uid);
      }
      return repassar(req, r, await r.text());
    }
  }

  if (metodo === "GET" && seg[0] === "accounts" && seg.length === 1) {
    const itemId = q.get("itemId");
    if (!itemId || !(await ehDono(uid, itemId))) {
      return resposta(req, 404, { erro: "item_nao_encontrado" });
    }
    const params = new URLSearchParams({ itemId });
    if (q.get("type")) params.set("type", q.get("type")!);
    const r = await pluggy("GET", `/accounts?${params}`);
    return repassar(req, r, await r.text());
  }

  // Posições de investimento de um item (paginado por page/pageSize).
  if (metodo === "GET" && seg[0] === "investments" && seg.length === 1) {
    const itemId = q.get("itemId");
    if (!itemId || !(await ehDono(uid, itemId))) {
      return resposta(req, 404, { erro: "item_nao_encontrado" });
    }
    const params = new URLSearchParams({ itemId });
    for (const k of ["page", "pageSize"]) {
      const v = q.get(k);
      if (v && /^\d{1,4}$/.test(v)) params.set(k, v);
    }
    const r = await pluggy("GET", `/investments?${params}`);
    return repassar(req, r, await r.text());
  }

  // Transações: /v2/transactions (cursor). O /transactions antigo responde 410
  // para aplicações novas da Pluggy.
  if (
    metodo === "GET" && seg.length === 2 && seg[0] === "v2" &&
    seg[1] === "transactions"
  ) {
    const accountId = q.get("accountId");
    const itemId = accountId ? await itemDaConta(accountId) : null;
    if (!itemId || !(await ehDono(uid, itemId))) {
      return resposta(req, 404, { erro: "conta_nao_encontrada" });
    }
    const params = new URLSearchParams({ accountId: accountId! });
    for (const k of ["dateFrom", "dateTo", "createdAtFrom", "after"]) {
      const v = q.get(k);
      if (v) params.set(k, v);
    }
    const r = await pluggy("GET", `/v2/transactions?${params}`);
    return repassar(req, r, await r.text());
  }

  return resposta(req, 403, { erro: "rota_nao_permitida" });
}

Deno.serve(async (req) => {
  const r = await atender(req);
  if (r.status >= 400 && r.status !== 401) {
    registrarFalha(`resposta ${req.method}`, r.status);
  }
  return r;
});
