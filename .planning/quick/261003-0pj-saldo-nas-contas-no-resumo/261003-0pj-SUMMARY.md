---
phase: quick-261003-0pj
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-0pj — "Saldo nas contas" no Resumo

## Contexto

Continuação da 261003-0a6: o "Saldo do mês" é o fluxo do mês e nunca fica
igual ao saldo que o banco mostra. O saldo real de cada conexão já vinha em
toda sincronização (`saldoContasCents`), mas só aparecia no patrimônio dos
relatórios.

## O que mudou

- `open_finance/domain/saldo_nas_contas.dart`: `SaldoNasContas`/`SaldoBanco` e
  `saldoNasContas(contas)` (soma das conexões com saldo; data = atualização
  mais antiga; null sem saldo). `saldoNasContasProvider`.
- Resumo: card "Saldo nas contas" antes do seletor de mês — total, valor por
  banco (com mais de um), "Atualizado hoje/ontem/em dd/MM às HH:mm"; negativo
  em vermelho; toque abre os bancos conectados. Sem faturas de cartão.
- Só aparece quando algum banco conectado já informou saldo (aparelhos que
  ainda não sincronizaram desde a 1.2.3 mostram depois da próxima
  sincronização automática).

## Verificação

- `flutter analyze`: só os 9 infos que já existiam.
- `flutter test`: 392 passando (novos: função, texto de atualização, widget
  com duas contas e sem conta).
- Web publicada pelo push na `main` (sem APK, a pedido).
