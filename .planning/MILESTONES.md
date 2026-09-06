# Milestones

## v1.0 MVP (Shipped: 2026-09-06)

**Phases completed:** 3 phases, 9 plans (Phase 1: Fundação e Acesso; Phase 2: Lançamentos Manuais; Phase 3: Ditado por Voz — Core)

**Key accomplishments:**

- **Fase 1 — Fundação e Acesso:** app Flutter criado com tema PT-BR, navegação e build web; backend Supabase (projeto `meubolso` sa-east-1, auth e-mail sem confirmação para usuário único, RLS, `.env`/segredos fora do git); login/cadastro com sessão persistente + deploy no GitHub Pages.
- **Fase 2 — Lançamentos Manuais:** schema `lancamentos` + RLS + realtime aplicado no remoto; data layer Dart (model em centavos/BRL, repository stream+CRUD, providers); telas S5 (lista com realtime) e S6 (formulário) com edição/exclusão e deploy web validado.
- **Fase 3 — Ditado por Voz (Core):** captura push-to-talk (record/opus) + cliente Gemini REST (áudio→JSON) com retry 429/500/502/503 e prompt reforçado; telas S7 (ditado) e S8 (confirmação) com correção por voz campo-a-campo; fluxo fim-a-fim testado (81 testes verdes) + deploy com `GEMINI_API_KEY`; **UAT aprovado no real pelo usuário** com `gemini-3.5-flash-lite` (free tier, sem custo).

**Stats:** 28 commits; 120 arquivos alterados em `app/`, ~7.3k linhas adicionadas (+ scaffolding Flutter); 28 arquivos Dart de app (~90 KB); timeline 2026-09-05 → 2026-09-06 (2 dias).

**Known deferred items at close:** 0 (audit-open limpo).
**Known gaps:** `01-01-SUMMARY.md` indisponível (fase 01 registra 3 plans, 2 summaries); validação em dispositivo Android/iOS pendente de toolchain (PLAT-02: código Flutter multi-plataforma, build web validado).

---