---
phase: quick-261003-in0
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-in0 — Atualização automática dos bancos às 8h, 14h e 20h

## O que foi feito

- Migration `20261003162629_atualizacao_automatica_bancos`: `pg_cron` +
  `pg_net`; segredo gerado no Vault (`cron_atualizar_bancos`); RPC
  `cron_atualizar_bancos_confere` (só service role); job `atualizar-bancos`
  em `0 11,17,23 * * *` UTC (8h/14h/20h de Brasília).
- Edge Function `atualizar-bancos` (sem JWT; segredo no cabeçalho
  `x-cron-secret`): responde 202 e, em segundo plano, pede `PATCH /items/{id}`
  às conexões de quem tem acesso ativo, de 5 em 5; pula as que dependem do
  usuário (erro de login / esperando) e as do Meu Pluggy. Log só com
  contagens. Teste manual por `somente_usuario`.

## Descoberta

A Pluggy **recusa** o `PATCH` de conexões Meu Pluggy (conector 200): 400
"MeuPluggy item cant be updated". As 4 conexões do dono são Meu Pluggy; essas
continuam com a sincronização diária automática da própria Pluggy. O
agendamento só força atualização de conexões diretas com o banco.

## Verificação

- Função: 401 sem segredo e com segredo errado.
- Teste com as conexões do dono (pelo banco, segredo do Vault): 202;
  1ª rodada `patch_400` ×4 (Meu Pluggy) → ajustado; depois `meu_pluggy: 4`,
  sem erro.
- Advisor de segurança: nada novo (a RPC não é executável por
  `anon`/`authenticated`).

## Pendente

- Ver no log da rodada das 14h (17:00 UTC) quantas conexões de clientes são
  diretas (`pedido`) e quantas Meu Pluggy.
- Se o dono quiser mais de uma atualização por dia com Meu Pluggy: só com
  conexões diretas (widget Connect no conector do banco) — avaliar plano da
  Pluggy e limites do Open Finance.
