// Indicadores públicos de mercado (Banco Central e IBGE) para o Guia de
// investimentos. Não recebe nem devolve dado do usuário; o login é exigido só
// para a função não virar um proxy aberto. O SGS antigo (api.bcb.gov.br) saiu
// do ar em 2026, então cada indicador vem da fonte que ainda responde, e cada
// um falha sozinho (vira null) sem derrubar os outros.
import { hojeEmBrasilia, preambulo, resposta } from "../_shared/seguranca.ts";

const TEMPO_MAXIMO_MS = 8_000;

async function lerJson(url: string): Promise<unknown> {
  const r = await fetch(url, {
    headers: { "Accept": "application/json", "User-Agent": "MeuBolso/1.0" },
    signal: AbortSignal.timeout(TEMPO_MAXIMO_MS),
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return await r.json();
}

type Reuniao = {
  DataReuniaoCopom?: string;
  MetaSelic?: number;
};

/** Meta Selic vigente e a anterior (histórico do Copom no site do BCB). */
async function selic() {
  const j = await lerJson(
    "https://www.bcb.gov.br/api/servico/sitebcb/historicotaxasjuros",
  ) as { conteudo?: Reuniao[] };
  const reunioes = (j.conteudo ?? [])
    .filter((c) => typeof c.MetaSelic === "number" && c.DataReuniaoCopom)
    .sort((a, b) =>
      String(b.DataReuniaoCopom).localeCompare(String(a.DataReuniaoCopom))
    );
  const atual = reunioes[0];
  if (!atual) return null;
  return {
    meta: atual.MetaSelic,
    reuniao: String(atual.DataReuniaoCopom).slice(0, 10),
    anterior: reunioes[1]?.MetaSelic ?? null,
  };
}

type LinhaFocus = {
  Indicador: string;
  Data: string;
  DataReferencia: string;
  Mediana: number;
};

/** Boletim Focus mais recente: Selic e IPCA do ano e do próximo. */
async function focus() {
  const filtro = "(Indicador eq 'Selic' or Indicador eq 'IPCA') and " +
    "baseCalculo eq 0";
  const url = "https://olinda.bcb.gov.br/olinda/servico/Expectativas/" +
    "versao/v1/odata/ExpectativasMercadoAnuais?$top=40" +
    `&$filter=${encodeURIComponent(filtro)}` +
    `&$orderby=${encodeURIComponent("Data desc")}` +
    "&$format=json&$select=Indicador,Data,DataReferencia,Mediana";
  const j = await lerJson(url) as { value?: LinhaFocus[] };
  const linhas = j.value ?? [];
  if (linhas.length === 0) return null;
  const data = linhas[0].Data;
  const ano = Number(hojeEmBrasilia().slice(0, 4));
  const doIndicador = (indicador: string) =>
    linhas
      .filter((l) =>
        l.Indicador === indicador && l.Data === data &&
        [ano, ano + 1].includes(Number(l.DataReferencia))
      )
      .map((l) => ({ ano: Number(l.DataReferencia), mediana: l.Mediana }))
      .sort((a, b) => a.ano - b.ano);
  return { data, selic: doIndicador("Selic"), ipca: doIndicador("IPCA") };
}

/** IPCA acumulado em 12 meses (IBGE, tabela 1737, variável 2265). */
async function ipca12m() {
  const j = await lerJson(
    "https://apisidra.ibge.gov.br/values/t/1737/n1/all/v/2265/p/last%201",
  ) as Array<Record<string, string>>;
  const linha = Array.isArray(j) ? j[1] : undefined;
  const valor = Number(linha?.V);
  if (!linha || !Number.isFinite(valor)) return null;
  return { valor, referencia: linha.D3N ?? null };
}

/** "MM-DD-AAAA" no fuso de Brasília (formato do PTAX). */
function dataPtax(d: Date): string {
  const [mes, dia, ano] = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Sao_Paulo",
    month: "2-digit",
    day: "2-digit",
    year: "numeric",
  }).format(d).split("/");
  return `${mes}-${dia}-${ano}`;
}

/** Último dólar PTAX (venda) dos últimos 10 dias. */
async function dolar() {
  const fim = new Date();
  const inicio = new Date(fim.getTime() - 10 * 24 * 60 * 60 * 1000);
  const url = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/" +
    "odata/CotacaoDolarPeriodo(dataInicial=@dataInicial," +
    "dataFinalCotacao=@dataFinalCotacao)" +
    `?@dataInicial='${dataPtax(inicio)}'` +
    `&@dataFinalCotacao='${dataPtax(fim)}'` +
    `&$format=json&$orderby=${encodeURIComponent("dataHoraCotacao desc")}` +
    "&$top=1";
  const j = await lerJson(url) as {
    value?: Array<{ cotacaoVenda: number; dataHoraCotacao: string }>;
  };
  const c = j.value?.[0];
  if (!c || typeof c.cotacaoVenda !== "number") return null;
  return { venda: c.cotacaoVenda, data: c.dataHoraCotacao.slice(0, 10) };
}

async function seguro<T>(
  nome: string,
  buscar: () => Promise<T>,
): Promise<T | null> {
  try {
    return await buscar();
  } catch (e) {
    console.warn(JSON.stringify({
      indicador: nome,
      erro: e instanceof Error ? e.message : String(e),
    }));
    return null;
  }
}

Deno.serve(async (req) => {
  const usuario = await preambulo(req, "indicadores", 30);
  if (usuario instanceof Response) return usuario;

  const [s, f, i, d] = await Promise.all([
    seguro("selic", selic),
    seguro("focus", focus),
    seguro("ipca12m", ipca12m),
    seguro("dolar", dolar),
  ]);
  console.log(JSON.stringify({
    selic: s !== null,
    focus: f !== null,
    ipca12m: i !== null,
    dolar: d !== null,
  }));
  return resposta(req, 200, {
    consultadoEm: new Date().toISOString(),
    selic: s,
    focus: f,
    ipca12m: i,
    dolar: d,
  });
});
