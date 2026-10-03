---
phase: quick-261003-lid
plan: 01
type: quick
date: 2026-10-03
---

# Quick 261003-lid — Guia de investimentos no plano gratuito do Gemini

## Pedido

"Apareceu esse erro": o guia mostrou "IA indisponível no momento (HTTP 404)".

## Diagnóstico (logs da função `ditado`)

- `gemini-3.5-flash-lite` com busca → `429 RESOURCE_EXHAUSTED` na hora. A
  tabela de preços do Gemini diz que a Busca Google é **"Not available" no
  plano gratuito** para todos os modelos 3.x. A chave do projeto está no
  nível gratuito.
- `gemini-2.5-flash` → `404 NOT_FOUND`: o Google restringiu os modelos 2.5 a
  quem já os usava; a chave é de 28/09/2026. Os candidatos de fallback
  (2.5/2.0/1.5) estão todos fora — vale também para o ditado.
- O SGS do Banco Central (`api.bcb.gov.br`) não existe mais no DNS
  (NXDOMAIN no Google e na Cloudflare). Respondem: histórico do Copom no
  site do BCB, Focus e PTAX no Olinda, IPCA no SIDRA/IBGE.

## Tarefas

1. Edge Function nova `indicadores` (JWT + acesso ativo + cota): meta Selic e
   última decisão do Copom, Focus (Selic e IPCA do ano e do próximo), IPCA 12
   meses e dólar PTAX. Cada indicador falha sozinho (null).
2. `ditado`: a Busca Google só vai ao Gemini com o segredo `BUSCA_GOOGLE=1`
   (exige faturamento); sem ele, o pedido do guia segue sem a ferramenta (cota
   e tempo do guia continuam). Allowlist de modelos: 3.5-flash-lite,
   3.5-flash, 3.1-flash-lite.
3. App: `IndicadoresMercado` (texto para o prompt + fontes BCB/IBGE),
   repositório pela função, controller busca os indicadores antes do guia;
   prompt usa os indicadores e não inventa dados de hoje sem busca; fallback
   do guia = 3.5-flash; candidatos do ditado = 3.5-flash e 3.1-flash-lite.
4. Testes, deploy das funções, docs, commit, push.
