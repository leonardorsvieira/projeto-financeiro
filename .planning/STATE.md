---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: In progress
stopped_at: Fase 7 completa (07-01 07-02); receitas por voz + saldo do mês com entradas/saídas
last_updated: "2026-09-07T18:00:00Z"
last_activity: 2026-09-07 — Fase 7 (VOZ-02) implementada: coluna `tipo`, ditado/form com toggle despesa/receita, saldo do mês com entradas − saídas; 133 testes passam; analyze 0 issues; web + APK OK
progress:
  total_phases: 8
  completed_phases: 7
  total_plans: 28
  completed_plans: 19
  percent: 68
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-06 after v1.0)

**Core value:** O usuário dita um gasto, recebimento ou investimento pela voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar.
**Current focus:** Fase 7 concluída (receitas por voz + saldo no mês). Próximo: Fase 8 — Investimentos (milestone v1.1)

## Current Position

Phase: 7 — Recebimentos por Voz (concluída)
Plan: 07-01 ✅, 07-02 ✅
Status: **Fase 7 completa** — coluna `lancamentos.tipo` (despesa/receita); ditado e formulário com toggle Despesa/Receita (SegmentedButton + correção por voz do tipo); card "Saldo do mês" no Resumo com Entradas/Saídas/Saldo/Previsto; donut/metas/próximos vencimentos filtram só despesas; lista mostra receita verde com `+` e badge "Receita".
Last activity: 2026-09-07 — Fase 7 implementada; 133 testes passam; build web + APK OK

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
| 6 (Dashboard e Metas) | 3 | 3 | 1.0 |
| 7 (Recebimentos por Voz) | 2 | 2 | 1.0 |

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
- [Fase 6]: Decisões confirmadas pelo usuário: (1) saldo = gastos do mês (real+previsto), receitas só na F7; (2) donut com `fl_chart`; (3) `/home` ganha tabs Resumo|Lançamentos (HomeScreen), lista vira aba; (4) metas = limite mensal recorrente por categoria (editável/excluível) em tabela nova `metas` no Supabase
- [06-01]: `/home` → `HomeScreen` (ConsumerStatefulWidget, TabBar Resumo|Lançamentos com TabBarView); `DashboardScreen` = aba Resumo (card gastos real/previsto via `resumoMesProvider`, próximos vencimentos top5 + "Ver todos", RefreshIndicator); `LancamentosListScreen` virou corpo puro; `lembretes_preferencias_dialog.dart` expõe `abrirPreferenciasLembretes`; `resumoMesProvider` (real = data no mês, previsto = vencimento no mês com data fora); testes: +4 (resumo x2, dashboard x2), ajustados flow/ditado/router/smoke/vencimentos/lembretes; build_apk.ps1 corrigido (cmd /c + 2>&1 para stderr do Gradle não abortar com $ErrorActionPreference=Stop)
- [06-02]: `fl_chart: ^1.2.0`; `gastosPorCategoriaMesProvider` (soma por categoria do mês vigente, ordenado desc); `_DonutGastosCategoria` no Resumo (donut 200x200 + legenda cor/categoria/R$/%, paleta fixa com fallback, empty "Sem gastos neste mês."); +3 testes; analyze 0, 110 testes, web + APK OK
- [06-03]: Migration `20260907150000_create_metas.sql` (tabela `metas` + RLS + realtime) aplicada no remoto via `supabase db push --linked` (também aplicou 04-migration itinerante pendente) — PAT revogado após uso; `Meta` + `MetasRepository` + `SupabaseMetasRepository` (stream por `created_at`); `metasStreamProvider` + `metasComProgressoProvider` (junção com `gastosPorCategoriaMesProvider`, pct/estourou/quaseEstourada); `MetasScreen` dedicada (`/metas`, AppBar ícone track_changes, FAB nova meta, dialog select categoria + valor R$, menu editar/excluir); seção `Metas` no Resumo (progresso ok verde / âmbar ≥80% / vermelho >100%, "Gerenciar"/"Criar"); `_coresCategorias` extensível; +8 testes (2 provider, 4 tela metas, 2 dashboard); analyze 0, 118 testes, web + APK OK
- [Cleanup v1.1]: Pendentes das fases 4-6 corrigidos: ROADMAP Fase 6 `[x]` + Progress `3/3 Complete`; PROJECT.md marca Fases 4/5/6 ✓ ("Concluído (v1.1)") restam F7/F8; `.planning/REQUIREMENTS.md` recriado para o milestone v1.1 (13/22 validados F4-6; pendentes VOZ-02 F7 + INV-01..07/VOZ-03 F8; todo do STATE anteriormente pendente); navegação vencimento → edição do lançamento implementada (`proximos_vencimentos_screen.dart` onTap → `/lancamentos/:id`, +1 teste); `.continue-here.md` órfão da Fase 3 removido; analyze 0, 119 testes
- [Fase 7]: Decisões recomendadas aplicadas: coluna `tipo` (default 'despesa', check despesa/receita) + migration aplicada no remoto; `TipoLancamento` enum no domínio; receitas mantêm valor positivo; receita não usa vencimento/fixa/itens. `RascunhoLancamento.tipo` + `CampoDitado.tipo` + correção por voz; prompt Gemini com sinais de receita (recebi/ganhei/salário/...) e fallback despesa.
- [07-01]: Migration `20260907160000_add_tipo_lancamento.sql` aplicada no remoto; `Lancamento.tipo` (copyWith/toMap/fromMap fallback despesa); `LancamentosRepository.create/update` com `tipo`; `SupabaseLancamentosRepository` (cópia fixa preserva tipo); `ConfirmacaoDitadoScreen` toggle Despesa/Receita + mic de tipo + vencimento oculto em receita; `LancamentoFormScreen` idem; +testes; mics da confirmação reposicionados (índices `.at()` ajustados em testes)
- [07-02]: `ResumoMes` com `entradasCents`/`saidasCents`/`previstoCents` + `saldoCents = entradas − saídas` + alias `realCents` (compat); `gastosPorCategoriaMesProvider` e `proximosVencimentosProvider` filtram despesas; card "Saldo do mês" (Entradas/Saídas/Saldo/Previsto, donut usa saídas); lista: receita verde com `+R$` e badge "Receita", despesa `-R$` vermelha; analyze 0, 133 testes, web + APK OK

### Pending Todos

- _(nenhum)_ — todo anterior "Redefinir REQUIREMENTS.md" concluído em 2026-09-07 (arquivo criado).

### Blockers/Concerns

None yet.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-09-07 (3ª sessão do dia)
Stopped at: Fase 7 (VOZ-02) completa — receitas por voz + saldo do mês com entradas/saídas. Próximo: Fase 8 (Investimentos).
Resume file: None

## Operator Next Steps

- **Executar Fase 8** — Investimentos (INV-01..07 + VOZ-03) por voz e manual; planejar 08-xx.
- **_Nota segurança:_** PAT do Supabase exposto no chat — **revogar** em Account Settings → Access Tokens. (O token usado foi aplicado e deve ser revogado agora.)
