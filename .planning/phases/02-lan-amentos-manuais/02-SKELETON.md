# Walking Skeleton — Meu Bolso

**Phase:** 2 — Lançamentos Manuais
**Generated:** 2026-09-06
**Verified:** skeleton Fase 1 OK (Flutter 3.47.2, web, auth Supabase, GH Pages 200). Fase 2 em execução — contrato abaixo reflete as decisões planejadas (02-CONTEXT).

## Capability Proven End-to-End

> Um usuário logado registra despesas manualmente (descrição, valor BRL, categoria, forma de pagamento, data, vencimento) com a lista sincronizada na nuvem em todas as sessões — isolada por conta via RLS — e edita/exclui com confirmação.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.47.2 (stable, Dart 3.13) | Código único Android + iOS + Web; web é alvo first-class (validação atual) |
| App layout (monorepo) | `app/` no repo raiz | Repo único com .planning/ + código; backend é Supabase (sem código server próprio) |
| State management | flutter_riverpod | Providers simples; `StreamProvider` consumindo o stream realtime do Supabase |
| Navigation | go_router | Rotas + redirect por auth já em produção; novas rotas `/lancamentos*` seguem o mesmo padrão |
| Backend / dados | Supabase (Postgres + Auth + Realtime), free tier, **sa-east-1** | Tabela `lancamentos` com RLS por `auth.uid()`; padrão oficial `.stream(primaryKey: ['id'])` |
| Auth storage | supabase_flutter persistência padrão (shared_preferences) na Fase 1 — **placeholder**; hardening com flutter_secure_storage avaliado quando dados sensíveis relevantes existirem | Dados já existem agora; troca é pontual e pode ocorrer ainda na Fase 2 se viável sem risco |
| Modelo monetário | `valor_cents bigint` no banco; `Lancamento.valorCents int` no Dart; conversão estrita texto↔centavos em `lancamento_converter.dart`; formatação BRL via intl (`R$ 1.234,56`) | Sem ponto-flutuante em dinheiro (T-04-04) |
| Realtime | Tabela publicada em `supabase_realtime` (migration); stream do cliente emite estado inicial + mudanças | Sync entre dispositivos sem polling |
| Camada de dados | `LancamentosRepository` (abstract) + `SupabaseLancamentosRepository`; providers `lancamentosRepositoryProvider` e `lancamentosStreamProvider`; fakes nos testes | Testável sem rede; RLS é a regra de autorização única |
| Deploy web | GitHub Pages via Actions; `--base-href=/projeto-financeiro/`; segredos em repo secrets (dart-define) | Grátis, contínuo no push |
| UI | Material 3, seed `0xFF0B7A4B`, PT-BR, BRL; S5 lista + S6 form (UI-SPEC 02) | Tema e fluxos acordados |
| Secrets | `.env` local + `--dart-define`; `.env*` no .gitignore | Nunca versionar credenciais (PLAT-05) |

## Stack Touched (phase 1 = [x]/[ ]; phase 2)

- [x] Project scaffold (Flutter SDK + `app/` + lint + test runner)
- [x] Routing / Auth (go_router redirect, splash/login/signup/home) — Fase 1
- [x] Database — Supabase schema `lancamentos` + RLS + realtime migration aplicada (plan 02-01)
- [x] Camada de dados Dart — model/Lancamento, repository Stream, providers (plan 02-02)
- [x] UI — lista S5 + formulário S6 com testes fake (plan 02-03)
- [x] Deployment — GH Pages com URL pública (Fase 1 + redeploy F2)

## Out of Scope (Deferred to Later Slices)

- Recuperação de senha / reset (deep link) — fase futura
- Magic link / OAuth social
- Criptografia forte de sessão (flutter_secure_storage) — avaliar na Fase 2
- Receitas (Fase 7), investimentos (Fase 8), dashboard/saldo (Fase 6)
- Itens/parcelas, vencimentos em massa, recorrências (Fase 4), push (Fase 5)
- Categorias custom / importação (v2)
- IOS build real (Xcode) e Android toolchain (SDK) — iterar quando alvos móveis entrarem

## Subsequent Slice Plan

- Phase 3: Ditado por Voz (Core) — Groq STT + Gemini extração + confirmação
- Phase 4: Vencimentos, Itens e Recorrências — agenda, produtos, contas fixas
- Phase 5: Lembretes Push — notificações "X dias antes" e no dia
- Phase 6: Dashboard e Metas — saldo, gráfico por categoria, metas (puxa `lancamentos` existente)
- Phase 7: Recebimentos por Voz
- Phase 8: Investimentos

## Phase 2 Decisions Summary (02-CONTEXT)

D-14 schema `lancamentos` (centavos bigint, owner via `auth.uid()` default, timestamps, índice por user+data)
D-15 RLS por dono em todas as policies (SELECT/INSERT/UPDATE/DELETE), sem acesso anon
D-16 centavos inteiros; intl pt_BR com symbol `R$` apenas na UI
D-17 migrations versionadas em `supabase/migrations/`, aplicadas via `db push`/Management API
D-18 `LancamentosRepository.stream()` realtime + CRUD; `StreamProvider` no app
D-19 S5 lista + S6 form (validação, datas, dropdowns fixos)
D-20 realtime publication para sync entre dispositivos
D-21 `intl` p/ formatação BRL/datas