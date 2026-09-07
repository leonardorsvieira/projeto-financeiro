---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: In progress
stopped_at: Fase 5 completa (05-01 + 05-03); próxima = Fase 6 (Dashboard e Metas)
last_updated: "2026-09-07T05:10:00Z"
last_activity: 2026-09-07 — 05-03 implementado (diasAntes configurável 0-30, diálogo unificado horário+stepper, reagendamento); 103 testes passam; build web + APK OK
progress:
  total_phases: 8
  completed_phases: 5
  total_plans: 28
  completed_plans: 14
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-06 after v1.0)

**Core value:** O usuário dita um gasto, recebimento ou investimento pela voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar.
**Current focus:** Planejamento da Fase 4 — Vencimentos, Itens e Recorrências (milestone v1.1)

## Current Position

Phase: 5 — Lembretes Push (completa)
Plan: 05-01 ✅, 05-03 ✅
Status: **Fase 5 completa** — 05-03 concluído: `diasAntes` configurável (0-30, padrão 3), diálogo unificado horário + stepper na S5, reagendamento automático, testes de borda
Last activity: 2026-09-07 — 05-03 implementado e commitado; 103 testes; build web + APK validados

## Performance Metrics

**Velocity:** N/A (no plans executed yet)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 (Fundação e Acesso) | 3 | 3 | 1.0 |
| 2 (Lançamentos Manuais) | 3 | 3 | 1.0 |
| 3 (Ditado por Voz — Core) | 3 | 3 | 1.0 |
| 4 (Vencimentos, Itens e Recorrências) | 4 | 4 | 1.0 |
| 5 (Lembretes Push) | 2 | 2 | 1.0 |

**Recent Trend:** N/A

## Accumulated Context

### Decisions

- [Boot]: Stack recomendada — Flutter + Supabase + Groq STT + Gemini (free tiers) — ver .planning/research/SUMMARY.md
- [Boot]: Execução paralela + git auto-commit a cada plano (config.json)
- [Boot]: Estrutura MVP vertical (cada fase entrega fatia utilizável)
- [Boot]: Dados financeiros nunca versionados (.gitignore cobre .env, planilhas, extratos, DBS)
- [Phase 1]: Supabase projeto `meubolso` sa-east-1 (ref tkfhthotspehsgvmpsjm); auth email sem confirmação (usuário único); `.env` fora do git com URL + anon/publishable key
- [Phase 1]: Deploy web no GitHub Pages (workflow deploy-pages, base-href /projeto-financeiro/); URLs hash-based (go_router default)
- [Phase 1]: Android toolchain ainda não instalada — alvo Android validação pendente (web já público)
- [Phase 2]: Lançamentos em centavos inteiros; categorias/formas de pagamento fixas PT-BR
- [Phase 3]: Captura por voz via Gemini `gemini-3.5-flash-lite` (free tier) com retry 3x (429/500/502/503); prompt com lista fixa e fallback
- [Milestone]: v1.0 arquivado e publicado (GH Pages); variante v1.1 inicia na Fase 4
- [Phase 4]: Itens = JSONB na tabela lancamentos; soma automática; editáveis no S6 e detalhe
- [Phase 4]: Fixa mensal = gera cópias independentes dos próximos meses (lazy, no app); serie_id uuid; só mensal
- [Phase 4]: Ditado itens = lista natural; soma confirmada; vencimento "dia 15" = próxima data com esse dia
- [Phase 4]: 4 plans planejados (04-01 modelo/UI, 04-02 recorrência lazy, 04-03 ditado itens/vencimento, 04-04 notificações locais)
- [Phase 4]: 04-01/04-02/04-03/04-04 implementados; migration SQL aplicada no Supabase remoto
- [Phase 4]: build_apk.ps1 criado (lê .env e injeta SUPABASE/GEMINI via --dart-define); APK debug corrigido (desugaring + defines)
- [04-04]: Notificações locais (flutter_local_notifications 22.3.0) T-3/T-0 horário configurável; gradle desugaring + multiDex + compileSdk 36
- [Phase 5]: 05-01 tela "próximos vencimentos" (lista filtrada/ordenada, pull-to-refresh, badges) e 05-03 config "X dias antes" (diasAntes 0-30, padrão 3) unificada com horário no diálogo S5 — concluídos; 05-02 push FCM/APNs adiado (pós v1.1)
- [05-03]: `PreferenciasLembretes.diasAntes` (0-30, normalizado); chave `lembretes_dias_antes`; `datasDeAgendamento(venc, hora, minuto, diasAntes)` ordena T-X cronológico antes de T-0; tipo da notificação `xd` (migrou de `3d`, cancelamento ajustado); `alterarPreferencias` substitui `alterarHorario`

### Pending Todos

- Redefinir REQUIREMENTS.md para o milestone v1.1 (a Fase 4 usa micro-requirements próprios durante o planejamento)

### Blockers/Concerns

None yet.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-09-07
Stopped at: Fase 5 (05-01 + 05-03) implementada e commitada; próxima = Fase 6 (Dashboard e Metas)
Resume file: None

## Operator Next Steps

- **Iniciar Fase 6 (Dashboard e Metas)** — planejar 06-01 (card de saldo do mês), 06-02 (gráfico por categoria), 06-03 (metas por categoria com progresso)
- **_Nota segurança:_** revogar o PAT do Supabase exposto no chat (Account Settings → Access Tokens)
