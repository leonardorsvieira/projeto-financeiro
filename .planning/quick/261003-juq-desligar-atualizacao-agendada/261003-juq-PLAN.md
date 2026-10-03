---
phase: quick-261003-juq
plan: 01
type: quick
date: 2026-10-03
---

# Quick 261003-juq — Desligar a atualização agendada e descobrir o horário do Meu Pluggy

## Pedido

1. "Que horas é feita a atualização [diária do Meu Pluggy] hoje?"
2. "Pode desligar" o agendamento das 8h/14h/20h (não faz nada: todas as
   conexões são Meu Pluggy, que a Pluggy não deixa atualizar por API).

## Tarefas

1. `atualizar-bancos`: log de diagnóstico por conexão, sem identificadores nem
   valores — conector, status, `lastUpdatedAt` e, se a Pluggy mandar,
   `nextAutoSyncAt`/`autoSyncDisabledAt`. Rodar só nas conexões do dono.
2. Migration `cron.unschedule('atualizar-bancos')`. A função, o segredo do
   Vault e a RPC ficam (religar = `cron.schedule` da migration
   `20261003162629`); documentar no CLAUDE.md.
3. Docs, commit, push.
