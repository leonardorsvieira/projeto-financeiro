---
phase: quick-261003-gle
plan: 01
type: quick
date: 2026-10-03
---

# Quick 261003-gle — Fatura aberta pelo `billId` do Open Finance

## Problema (dono, 2026-10-03)

Cartão Mercado Pago no painel acima do que ele deve: o banco mostra a fatura
atual em **R$ 217,00** = compras de 17/09 (R$ 216,00 + R$ 1,00). A 2ª parcela
de 09/09 (R$ 43,11) e o estorno de 07/09 (R$ 344,90) são da fatura anterior.

A fatura aberta era estimada pelas compras importadas desde o fechamento da
última fatura; a Pluggy não traz a data de fechamento, então o corte era
"vencimento − 7 dias", que caiu entre 07/09 e 09/09 → R$ 260,11.

## Decisão

Fatura aberta vinda do próprio Open Finance: na sincronização, as transações
do cartão desde 25 dias antes do último vencimento; soma as que ainda **não
têm fatura** (`creditCardMetadata.billId` vazio), com data antes do próximo
vencimento (fora parcelas de faturas seguintes), sem pagamento de fatura.
Compra soma, crédito/estorno subtrai (sinal do cartão). Se nenhuma transação
da janela tem `billId` (banco não informa), mantém a estimativa antiga.

Guardado em `CartaoOpenFinance.faturaAbertaCents`; `faturasDoMes` usa esse
valor para a fatura aberta quando todos os cartões do grupo o têm.

## Tarefas

1. `faturaAbertaDasTransacoes` (pura) + `_faturaAbertaDoCartao` no
   `_mapearItem`; `vencimentoSeguinte` público; campo novo e persistência.
2. `faturasDoMes` usa o valor do banco.
3. Testes, docs, push na `main`.
