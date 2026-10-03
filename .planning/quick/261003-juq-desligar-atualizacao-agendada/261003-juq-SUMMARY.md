---
phase: quick-261003-juq
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-juq — Desligar a atualização agendada e horário do Meu Pluggy

## Resultado

- **Agendamento desligado:** migration `20261003171809` (`cron.unschedule`).
  Função `atualizar-bancos`, segredo do Vault e RPC continuam para religar
  (repetir o `cron.schedule` da `20261003162629`).
- A rodada das 14h (17:00 UTC) chegou a rodar antes do desligamento: **5
  usuários, 11 conexões, todas Meu Pluggy** — o agendamento nunca teria
  efeito com os clientes atuais.
- **Horário da atualização do Meu Pluggy:** não é fixo. A Pluggy atualiza cada
  conexão 24 h depois da última atualização dela (`nextAutoSyncAt` =
  `lastUpdatedAt` + 24 h; uma das conexões do dono veio com +48 h). As 4
  conexões do dono foram atualizadas em 02/10 às 14:17, 14:23, 14:50 e 17:30
  (Brasília), quando foram conectadas; próximas: 03/10 14:23, 14:50, 17:30 e
  04/10 14:17.
- Nos logs de 01/10 a 03/10 não há aviso `item/updated`/`transactions/created`
  — nenhuma sincronização automática tinha acontecido ainda desde que as
  conexões foram criadas.
- `atualizar-bancos` ganhou log de diagnóstico por conexão (conector, status,
  `lastUpdatedAt`, `nextAutoSyncAt`, `autoSyncDisabledAt`; sem ids nem
  valores).
