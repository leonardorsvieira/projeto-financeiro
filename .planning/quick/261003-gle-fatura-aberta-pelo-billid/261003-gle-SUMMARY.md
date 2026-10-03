---
phase: quick-261003-gle
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-gle — Fatura aberta pelo `billId` do Open Finance

## Contexto

O dono viu o cartão Mercado Pago acima do que deve: o banco mostra a fatura
atual em R$ 217,00 (compras de 17/09: R$ 216,00 + R$ 1,00). O app estimava a
fatura aberta pelas compras importadas desde "vencimento − 7 dias" (a Pluggy
não traz a data de fechamento) e pegava também a 2ª parcela de 09/09
(R$ 43,11), que é da fatura anterior → provavelmente R$ 260,11.

## O que mudou

- `faturaAbertaDasTransacoes`: soma as transações do cartão sem
  `creditCardMetadata.billId` (ainda sem fatura), com data antes do próximo
  vencimento (parcelas de faturas seguintes ficam fora), sem pagamento de
  fatura; compra soma, estorno subtrai. Null se nenhuma transação da janela
  traz `billId`.
- Sincronização (`_mapearItem`): para cada cartão com faturas, busca as
  transações desde 25 dias antes do último vencimento e guarda
  `CartaoOpenFinance.faturaAbertaCents`.
- `faturasDoMes`: fatura aberta = a do banco quando todos os cartões do grupo
  a têm; senão, a estimativa antiga. `vencimentoSeguinte` público.

## Verificação

- `flutter analyze`: só os 9 infos antigos. `flutter test`: 415 passando,
  incluindo o caso real do Mercado Pago (dá R$ 217,00).
- Web publicada pelo push na `main`.

## Pendente

- Dono abrir o app (sincroniza) e conferir o Mercado Pago no painel. Se ainda
  mostrar a estimativa, o banco não informa `billId` — próximo passo seria um
  diagnóstico no `pluggy` (sem valores) para ver os campos das transações.
