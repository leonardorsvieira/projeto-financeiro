---
phase: quick-261003-m6f
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-m6f — "Sincronizar agora" já importa os últimos 12 meses

## Resultado

- "Sincronizar agora" (botão, ícone da barra e "Sincronizar" de cada banco)
  roda a sincronização normal e, ao terminar, `importarHistorico12Meses`.
  Rótulo: "Sincronizando…" → "Importando 12 meses…"; aviso final com a soma
  das transações novas. Sem banco conectado o histórico não roda; falha só
  no histórico mostra aviso próprio e mantém o que a sincronização trouxe.
- Botão "Importar últimos 12 meses" removido.
- `importarHistorico12Meses` não busca investimentos de novo (parâmetro
  `investimentos` em `_sincronizar`).
- Guia público `conectar-bancos-o3um1bnu.html` atualizado (um botão só).
- Custo: a importação de 12 meses usa algumas páginas por conta na função
  `pluggy` (cota 3.000 chamadas/dia por usuário); o dedup por `pluggy_id`
  impede duplicar.

## Verificação

- Teste novo `open_finance_screen_test.dart` (ordem 30 → 365 dias,
  investimentos uma vez, sem duplicar, falha no histórico).
- `flutter test`: 451 passando; `flutter analyze`: só os 9 avisos antigos.
