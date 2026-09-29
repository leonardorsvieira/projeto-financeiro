// Acesso à API da Pluggy com as credenciais que ficam só nos secrets.
export const PLUGGY = "https://api.pluggy.ai";

let apiKeyCache: { chave: string; expiraEm: number } | null = null;

export async function apiKey(): Promise<string | null> {
  if (apiKeyCache && apiKeyCache.expiraEm > Date.now()) return apiKeyCache.chave;
  const clientId = Deno.env.get("PLUGGY_CLIENT_ID");
  const clientSecret = Deno.env.get("PLUGGY_CLIENT_SECRET");
  if (!clientId || !clientSecret) return null;
  const r = await fetch(`${PLUGGY}/auth`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ clientId, clientSecret }),
  });
  if (!r.ok) throw new Error(`Pluggy /auth ${r.status}`);
  const { apiKey } = await r.json();
  // A apiKey da Pluggy vale 2h; renova antes.
  apiKeyCache = { chave: apiKey, expiraEm: Date.now() + 90 * 60 * 1000 };
  return apiKey;
}

export async function pluggy(
  metodo: string,
  caminho: string,
  corpo?: unknown,
): Promise<Response> {
  const chave = await apiKey();
  return fetch(`${PLUGGY}${caminho}`, {
    method: metodo,
    headers: { "X-API-KEY": chave!, "Content-Type": "application/json" },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
}
