---
phase: quick-261003-lid
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-lid — Guia de investimentos no plano gratuito do Gemini

## Causa do "IA indisponível (HTTP 404)"

- `gemini-3.5-flash-lite` + Busca Google → 429 RESOURCE_EXHAUSTED: a busca é
  "Not available" no plano gratuito para os modelos 3.x (a chave está no
  nível gratuito, confirmado no AI Studio).
- Fallback `gemini-2.5-flash` → 404: o Google restringiu o 2.5 a quem já o
  usava. Os candidatos 2.x do `GeminiCliente` (ditado incluso) estavam mortos.

## Resultado

- **Edge Function `indicadores`** (nova, JWT + acesso ativo + cota 30/dia):
  meta Selic 13,75% (Copom 16/09/2026, antes 14,00%), Focus (Selic e IPCA do
  ano e do próximo), IPCA 12 meses (IBGE) e dólar PTAX. O SGS
  `api.bcb.gov.br` não existe mais no DNS; fontes testadas uma a uma.
- **`ditado`:** Busca Google só com o segredo `BUSCA_GOOGLE=1`; sem ele o
  pedido do guia segue sem a ferramenta (cota `consultoria` e 80 s mantidos).
  Modelos permitidos: 3.5-flash-lite, 3.5-flash, 3.1-flash-lite. Log passa a
  ter a mensagem de erro do Google (sem conteúdo do pedido).
- **App:** `IndicadoresMercado` (texto com datas + fontes BCB/IBGE no guia),
  `EdgeIndicadoresRepository` (falha → null, guia sai igual), prompt usa os
  indicadores e não inventa dados de hoje sem busca; fallback do guia e do
  ditado = 3.5-flash / 3.1-flash-lite. Textos da tela e uma frase da Política
  ajustados (sem mudar a versão: BCB/IBGE não recebem dado do usuário).
- Funções `indicadores` e `ditado` publicadas (401 sem login).

## Verificação

- `flutter test`: 449 passando; `flutter analyze`: só os 9 avisos antigos.
- Fontes de dados testadas por HTTP (Copom, Focus, SIDRA, PTAX). Não testado
  ponta a ponta com login: conferir nos logs das funções após o próximo guia.

## Para ligar a Busca Google no futuro

Ativar faturamento no Google AI Studio e `supabase secrets set BUSCA_GOOGLE=1`
(5.000 buscas/mês grátis nos modelos 3.x, depois US$ 14 por 1.000).
