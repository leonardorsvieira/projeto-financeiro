// Exclusão da própria conta (LGPD, art. 18, VI: eliminação dos dados pessoais).
//
// Quem chama é o app, com o JWT do usuário. O id apagado vem SOMENTE do JWT
// verificado (`usuarioAutenticado`); o corpo da requisição é ignorado, então é
// impossível apagar a conta de outra pessoa.
//
// Passos:
//   1. Desconecta os bancos do usuário na Pluggy (best effort: se falhar, a
//      linha em `pluggy_items` some na cascata e o `pluggy-webhook` já ignora
//      item sem dono).
//   2. Apaga o usuário em auth.users. `lancamentos`, `metas`, `investimentos`,
//      `pluggy_items` e `uso_diario` referenciam auth.users com ON DELETE
//      CASCADE, então todos os dados do servidor saem junto.
//
// Não usa `preambulo`: excluir a conta não deve consumir cota diária.
import {
  admin,
  cabecalhosCors,
  resposta,
  usuarioAutenticado,
} from "../_shared/seguranca.ts";
import { apiKey, pluggy } from "../_shared/pluggy.ts";

/** Desfaz as conexões Pluggy do usuário. Nunca lança: falha só gera aviso. */
async function desconectarBancos(userId: string): Promise<void> {
  const { data, error } = await admin
    .from("pluggy_items")
    .select("item_id")
    .eq("user_id", userId);
  if (error) {
    console.warn(JSON.stringify({ etapa: "listar_itens", erro: error.message }));
    return;
  }
  if (!data || data.length === 0) return;

  try {
    // Lança se a autenticação na Pluggy falhar; devolve null sem credenciais.
    if (!(await apiKey())) {
      console.warn(JSON.stringify({ etapa: "pluggy_indisponivel" }));
      return;
    }
  } catch (e) {
    console.warn(JSON.stringify({
      etapa: "pluggy_indisponivel",
      erro: e instanceof Error ? e.message : String(e),
    }));
    return;
  }

  for (const { item_id } of data) {
    try {
      const r = await pluggy("DELETE", `/items/${encodeURIComponent(item_id)}`);
      // 404: já não existe na Pluggy, o que também serve.
      if (!r.ok && r.status !== 404) {
        console.warn(JSON.stringify({ etapa: "excluir_item", status: r.status }));
      }
      await r.body?.cancel(); // descarta o corpo da resposta
    } catch (e) {
      console.warn(JSON.stringify({
        etapa: "excluir_item",
        erro: e instanceof Error ? e.message : String(e),
      }));
    }
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cabecalhosCors(req) });
  }
  if (req.method !== "POST") {
    return resposta(req, 405, { erro: "metodo_nao_permitido" });
  }

  const usuario = await usuarioAutenticado(req);
  if (!usuario) return resposta(req, 401, { erro: "nao_autenticado" });

  try {
    await desconectarBancos(usuario.id);
    const { error } = await admin.auth.admin.deleteUser(usuario.id);
    if (error) throw error;
    return resposta(req, 200, { ok: true });
  } catch (e) {
    // Sem e-mail, id nem dados financeiros nos logs.
    console.error(JSON.stringify({
      etapa: "excluir_conta",
      erro: e instanceof Error ? e.message : String(e),
    }));
    return resposta(req, 500, { erro: "falha_ao_excluir" });
  }
});
