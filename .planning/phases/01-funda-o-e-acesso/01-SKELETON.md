# Walking Skeleton — Meu Bolso

**Phase:** 1
**Generated:** 2026-09-05

## Capability Proven End-to-End

> Um usuário abre o app no navegador, vê a tela inicial "Meu Bolso" e pode criar conta/entrar (auth Supabase) com a sessão persistindo entre aberturas — na web, em Android e preparado para iOS.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.47 (stable, Dart 3.11) | Código único Android + iOS + Web; 4 releases estáveis/ano; web é alvo first-class |
| App layout (monorepo) | `app/` no repo raiz | Repo único com .planning/ + código; backend é Supabase (sem código server próprio) |
| State management | flutter_riverpod | Padrão de facto em projetos Flutter; providers simples p/ auth e dados futuros |
| Navigation | go_router | Rotas nomeadas + redirect condicional por auth (estado de sessão) |
| Backend / auth | Supabase (Postgres + Auth), free tier, região **sa-east-1 (São Paulo)** | Latência p/ usuário BR; auth email/senha + persistência local |
| Auth storage | supabase_flutter com persistência padrão (shared_preferences) na Fase 1; **hardening futuro: flutter_secure_storage** | Dados financeiros não existem ainda; troca pontual em fase com dados sensíveis |
| Deploy web | GitHub Pages (repo público) via GitHub Actions; `--base-href=/projeto-financeiro/` | Grátis, direto no repo existente; URL pública de acesso de qualquer lugar |
| App identity | org `br.com.meubolso`, app `meubolso` | Identidade estável p/ Android applicationId / iOS bundle |
| UI | Material 3, seed `0xFF0B7A4B`, PT-BR, BRL, fuso America/Sao_Paulo | Tema financeiro acordado (01-UI-SPEC) |
| Secrets | `.env` local + `--dart-define`; `.env*` e `build/` sempre no .gitignore | Nunca versionar credenciais (PLAT-05) |

## Stack Touched in Phase 1

- [x] Project scaffold (Flutter SDK + `app/` + lint + test runner)
- [ ] Routing — Splash/Auth/Home (go_router) — plan 01-03
- [ ] Database — Supabase Auth (criação de conta/login reais) — plans 01-02/01-03
- [x] UI — tela inicial "Meu Bolso" com smoke test (widget) — plan 01-01
- [ ] Deployment — GH Pages com URL pública — plan 01-03

## Out of Scope (Deferred to Later Slices)

- Recuperação de senha / reset (exige deep link) — fase futura
- Magic link / OAuth social
- Dados do usuário (lançamentos, categorias, metas) — Fases 2-8
- Criptografia forte de sessão (flutter_secure_storage) — ativar antes da Fase 2 (dados sensíveis)
- Push notifications (APNs pago) — Fase 5 com fallback local
- iOS build real (exige Mac/Xcode) — validação em Mac/CI futuro; código já é multiplataforma

## Subsequent Slice Plan

Cada fase adiciona uma fatia vertical sobre este esqueleto sem alterar as decisões arquiteturais:

- Phase 2: Lançamentos Manuais — dados de despesas (Supabase schema + RLS), CRUD + sync
- Phase 3: Ditado por Voz (Core) — Groq STT + Gemini extração + confirmação
- Phase 4: Vencimentos, Itens e Recorrências — agenda, produtos, contas fixas
- Phase 5: Lembretes Push — notificações "X dias antes" e no dia
- Phase 6: Dashboard e Metas — saldo, gráfico por categoria, metas
- Phase 7: Recebimentos por Voz
- Phase 8: Investimentos