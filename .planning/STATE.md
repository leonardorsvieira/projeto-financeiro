---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: In progress
stopped_at: Milestone v1.1 completo (Fases 1-8); Open Finance/Pluggy + hardening multiusuário entregues
last_updated: "2026-09-29T21:50:00Z"
last_activity: 2026-09-29 — Quick 260929-pzt permissão INTERNET no manifest principal + APK debug novo + STATE atualizado
progress:
  total_phases: 8
  completed_phases: 8
  total_plans: 28
  completed_plans: 27
  percent: 96
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-06 after v1.0)

**Core value:** O usuário dita um gasto, recebimento ou investimento pela voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar.
**Current focus:** Milestone v1.1 concluído (Fases 1-8) + Open Finance (Pluggy/meu.pluggy.ai) e hardening multiusuário. Próximo: fechar o milestone (`/gsd-complete-milestone`) ou planejar o próximo.

## Current Position

Phase: 8 — Investimentos (concluída) — todas as 8 fases do roadmap completas
Plan: 08-01..08-05 ✅ (05-02 push FCM/APNs adiado de propósito — lembretes usam notificação local)
Status: **Milestone v1.1 completo.** Depois dele: Open Finance via Pluggy (Edge Functions `pluggy`/`pluggy-webhook`, meu.pluggy.ai direto, `/v2/transactions`, sincronização automática, sinal do cartão, categorias neutras) e hardening multiusuário (quick 260928-n3q).
Last activity: 2026-10-01 — quick 261001-l9o: LGPD (política, termos, aceite, exclusão de conta)

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

- Apagar pelo app o lançamento manual "Rescisão" R$ 4.280,47 (14/09/2026), duplicado do Pix importado de R$ 4.280,39.
- Testar no Android a conexão meu.pluggy.ai com o APK novo (autorizar no navegador → voltar → "Sincronizar Agora").

### Blockers/Concerns

- APK **release** falha em `minifyReleaseWithR8` (ProGuard). Debug funciona.
- Leaked password protection do Supabase exige plano Pro (não disponível).

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Quick Tasks Completed

| ID | Descrição | Data | Resumo |
|----|-----------|------|--------|
| 260928-n3q | Endurecimento de segurança multiusuário | 2026-09-28 | [SUMMARY](quick/260928-n3q-endurecimento-de-seguranca-multiusuario/260928-n3q-SUMMARY.md) |
| 260929-pzt | Permissão INTERNET no manifest + APK novo + STATE | 2026-09-29 | [SUMMARY](quick/260929-pzt-internet-manifest-apk-state/260929-pzt-SUMMARY.md) |
| 260929-r0j | Investimentos do Open Finance no Patrimônio | 2026-09-29 | [SUMMARY](quick/260929-r0j-importar-investimentos-open-finance-patr/260929-r0j-SUMMARY.md) |
| 260929-rf2 | Patrimônio somente Open Finance | 2026-09-29 | [SUMMARY](quick/260929-rf2-patrimonio-somente-open-finance/260929-rf2-SUMMARY.md) |
| 260929-rou | Rendimento por investimento (Open Finance) | 2026-09-29 | [SUMMARY](quick/260929-rou-rendimento-por-investimento-open-finance/260929-rou-SUMMARY.md) |
| 260930-arb | Remover telas de proventos e diagnóstico Pluggy | 2026-09-30 | [SUMMARY](quick/260930-arb-remover-telas-proventos-e-diagnostico-pl/260930-arb-SUMMARY.md) |
| 260930-j4c | Visual glassmorphism (aero glass) no app inteiro | 2026-09-30 | [SUMMARY](quick/260930-j4c-glassmorphism-aero-glass-no-app-inteiro/260930-j4c-SUMMARY.md) |
| 260930-jxk | Tema de identidade Caderneta (substitui o vidro) | 2026-09-30 | [SUMMARY](quick/260930-jxk-tema-caderneta-no-app/260930-jxk-SUMMARY.md) |
| 260930-kj5 | Textos do app na voz Caderneta | 2026-09-30 | [SUMMARY](quick/260930-kj5-voz-caderneta-nos-textos/260930-kj5-SUMMARY.md) |
| 260930-lc9 | Ícone Carimbo + widget Agenda 4×2 (Android) | 2026-09-30 | [SUMMARY](quick/260930-lc9-icone-carimbo-e-widget-agenda/260930-lc9-SUMMARY.md) |
| 260930-lw9 | Ajustes visuais da Caderneta (pauta, cores, título) | 2026-09-30 | [SUMMARY](quick/260930-lw9-ajustes-visuais-caderneta/260930-lw9-SUMMARY.md) |
| 260930-q6z | Caderneta suave (cantos arredondados) + correções do APK/widget | 2026-09-30 | [SUMMARY](quick/260930-q6z-caderneta-suave-cantos-arredondados/260930-q6z-SUMMARY.md) |
| 260930-qmc | Ícones Phosphor Duotone no app inteiro | 2026-09-30 | [SUMMARY](quick/260930-qmc-icones-phosphor-duotone-no-app/260930-qmc-SUMMARY.md) |
| 261001-ktp | Assinatura de produção + APK comercial 1.1.0 (64 bits) | 2026-10-01 | [SUMMARY](quick/261001-ktp-assinatura-de-producao-do-apk/261001-ktp-SUMMARY.md) |
| 261001-l9o | LGPD: política, termos, aceite e exclusão de conta | 2026-10-01 | [SUMMARY](quick/261001-l9o-lgpd-privacidade-termos-e-exclusao-de-co/261001-l9o-SUMMARY.md) |
| 261001-rmt | Página de e-mail confirmado (Site URL) | 2026-10-01 | [SUMMARY](quick/261001-rmt-pagina-de-confirmacao-de-email/261001-rmt-SUMMARY.md) |

## Session Continuity

Last session: 2026-09-29
Stopped at: Milestone v1.1 completo + Open Finance; APK debug regerado.
Resume file: None

## Operator Next Steps

- Instalar o APK debug novo e testar login, ditado e conexão meu.pluggy.ai.
- Apagar o lançamento "Rescisão" duplicado pelo app.
- Opcional: corrigir o R8/ProGuard do build release; `/gsd-complete-milestone` para arquivar a v1.1.
- (Ações de segurança do 260928-n3q — secrets rotacionados, confirmação de e-mail — já concluídas em 2026-09-29.)
