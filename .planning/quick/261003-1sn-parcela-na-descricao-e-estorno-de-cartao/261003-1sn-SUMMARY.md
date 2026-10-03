---
phase: quick-261003-1sn
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-1sn — Número da parcela na descrição e estorno de cartão abate despesas

## Contexto

O dono não reconheceu "MERCADOLIVRE*MERCADOLIVRE R$ 43,11 em 09/09": era a 2ª
parcela (o Mercado Pago lança parcelas no dia 9) de uma compra de R$ 344,90
em 8x feita em 30/08 e estornada em 07/09 (43,13 + 7 × 43,11 = 344,90). O
estorno entrava como "Receita".

## O que mudou

- **Parcela:** `descricaoComParcela` (app) e a mesma regra no
  `pluggy-webhook` (v8): " (n/total)" a partir de `creditCardMetadata`,
  dentro dos 200 caracteres, sem repetir se o banco já põe ("PARC 02/08").
  Classificação (fatura, Pix, categoria) continua pela descrição do banco.
- **Importados antigos:** `importadasPluggy()` (mapa `obs → descrição`, mesma
  consulta, agora ordenada para paginar estável) substitui
  `obsImportadasPluggy()`; `renomearImportada` atualiza só se a descrição
  ainda for a do banco (`precisaRenomearImportado`). Parcelas futuras são
  renomeadas na próxima sincronização; antigas fora da janela de 7 dias, pelo
  "Importar histórico".
- **Estorno de cartão:** `Lancamento.ehEstornoDeCartao` +
  `valorDespesaCents`. `resumoDoMes` (saldo do mês e histórico), gastos por
  categoria (donut e metas; categoria ≤ 0 sai; percentuais sobre o que
  aparece), painel por forma de pagamento e relatórios abatem o estorno das
  despesas. Saldo inalterado. Lista: selo "Estorno" e filtro de despesas.
  CSV/PDF: tipo "Estorno".

## Verificação

- `flutter analyze`: só os 9 infos antigos. `flutter test`: 412 passando
  (novos: parcela, renomear, estorno no resumo, categoria, painel,
  relatórios).
- `pluggy-webhook` publicado sem JWT (como antes): GET 405, item
  desconhecido 200 ignorado.
- Web publicada pelo push na `main`.

## Pendente

- O dono abrir o app (sincroniza e renomeia as parcelas futuras) e, para as
  antigas, usar "Importar histórico".
- Ainda falta a resposta dele sobre o valor da fatura do Mercado Pago no
  painel (fatura aberta pode estar deixando o estorno de 07/09 fora do corte).
