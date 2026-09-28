// Proxy autenticado para o Gemini (generateContent). A GEMINI_API_KEY fica só aqui,
// como secret do Supabase — nunca no app (o bundle web é público).
import { preambulo, resposta } from "../_shared/seguranca.ts";

const MODELOS_PERMITIDOS = new Set([
  "gemini-3.5-flash-lite",
  "gemini-2.5-flash",
  "gemini-2.0-flash",
  "gemini-1.5-flash",
]);

// Áudio em base64 + prompt; ditados reais ficam bem abaixo disso.
const TAMANHO_MAXIMO = 10 * 1024 * 1024;

Deno.serve(async (req) => {
  const usuario = await preambulo(req, "ditado", 150);
  if (usuario instanceof Response) return usuario;

  const chave = Deno.env.get("GEMINI_API_KEY");
  if (!chave) return resposta(req, 503, { erro: "ia_nao_configurada" });

  const texto = await req.text();
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

  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": chave },
      body: JSON.stringify(corpo),
    },
  );
  return resposta(req, r.status, await r.text());
});
