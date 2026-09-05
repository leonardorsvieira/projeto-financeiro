# Phase 1: Fundação e Acesso - Context

**Gathered:** 2026-09-05
**Status:** Ready for planning
**Source:** Discuss-phase (inline synthesis from project answers + user decisions)

<domain>
## Phase Boundary

Fraga base do projeto "Meu Bolso": app Flutter inicializado para Android, iPhone e Web, com login de usuário único (e-mail/senha) via Supabase Auth. Sessão persistente. Nenhum dado sensível no repositório público. É a fatia que prova toda a stack de ponta a ponta (Walking Skeleton).

**Não faz parte desta fase:** lançamentos, voz, dashboard, lembretes, investimentos — vêm nas fases seguintes. A home será um placeholder pós-login.
</domain>

<decisions>
## Implementation Decisions

### Plataforma e framework
- **D-01 | Framework:** Flutter (stable) — código único para Android + iOS + Web (fonte do projeto: app de celular e navegador no PC)
- **D-02 | Estrutura do repo:** monorepo com app em `app/` (Flutter); backend é gerenciado via Supabase (não há código backend próprio nesta fase além de migrations/config)
- **D-03 | Idiomas/região:** UI e textos em PT-BR, moeda BRL (pt_BR locale), fuso America/Sao_Paulo
- **D-04 | Tema visual:** Material 3, tema "financeiro" (tons de verde/escuro), tipografia padrão Flutter; ícones legíveis em qualquer plataforma

### Backend e dados
- **D-05 | Backend:** Supabase (Postgres + Auth + Storage/Realtime, quando necessário) no free tier; região **São Paulo (sa-east-1)**
- **D-06 | Auth:** Supabase Auth com e-mail/senha; sessão persistente localmente (supabase_flutter `PersistSessionTab`)
- **D-07 | Segredos:** URL e chave anon do Supabase vão em `.env`/`--dart-define`, **nunca no git**; `.gitignore` cobre `.env*`

### Estado e arquitetura do app
- **D-08 | Gerenciamento de estado:** Riverpod (`flutter_riverpod`) — leve, oficial para projetos Flutter, boa estruturação para fases futuras
- **D-09 | Arquitetura:** feature-first (`lib/features/auth/`, `lib/features/home/`), camadas `presentation` / `domain` / `data` dentro de cada feature — decisão de fundação que as fases 2-8 seguem
- **D-10 | Autenticação de sessão no app:** `AuthState` via Riverpod; telas: Splash → Auth (login/cadastro) → Home; rotas nomeadas (`go_router`)

### Deploy e CI
- **D-11 | Web deploy:** GitHub Pages (grátis, no repo existente) na branch `main`/docs — build web do Flutter publicado automaticamente
- **D-12 | Push (não entra na fase 1):** APNs exige conta Apple Developer ($99/ano); plano de fallback com notificação local agendada fica documentado para a Fase 5
- **D-13 | Ambiente dev:** Flutter SDK instalado localmente (Windows); `flutter doctor` limpo para Android + Web (iOS requer Mac — build iOS validado via CI/CD ou em Mac futuro)

### Claude's Discretion
- Nomes de classes/arquivos internos
- Paleta exata de cores dentro do tema "verde financeiro"
- Estrutura exata das telas de auth (dentro do UI-SPEC)
- Método técnico de build web p/ GitHub Pages (script/workflow de deploy)
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Research e planejamento
- `.planning/research/SUMMARY.md` — stack recomendada (Flutter + Supabase + Groq + Gemini free tiers) e pitfalls
- `.planning/ROADMAP.md` — fase 1 (goal, success criteria, requirements PLAT-01/02/03/05)
- `.planning/REQUIREMENTS.md` — critérios PLAT-01..05
- `.planning/STATE.md` — estado vivo do projeto (0% de progresso, fase 1 pronta p/ planejar)

### Segurança e privacidade
- `.gitignore` — proteção anti-dados-pessoais (`.env`, `dados/`, planilhas, DBS) — regra rígida: nunca versionar segredos

No external specs submitted — decisions in `<decisions>` cover phase scope. Pesquisa técnica renderá `01-RESEARCH.md` nesta fase.
</canonical_refs>

<specifics>
## Specific Ideas

- Instalação do Flutter: usuário autorizou instalar o SDK nesta máquina Windows
- Supabase: fluxo CLI (`supabase init` + acesso via token do usuário) — credenciais `.env`, nunca no git
- Web: deploy no GitHub Pages
- Primeiro app: nome exibido "Meu Bolso"
</specifics>

<deferred>
## Deferred Ideas

- **Open Finance / importação de extratos** — v2 (fora do escopo v1; ver REQUIREMENTS Out of Scope)
- **Assistente conversacional (IA)** — v2
- **Multiusuário/família** — v2 (COMP-01)
- **Notificações push reais** — Fase 5 (documenta-se aqui o custo APNs)
- **Dados financeiros reais do usuário** — nunca entram no repositório (restrição permanente)
</deferred>

---

*Phase: 01-funda-o-e-acesso*
*Context gathered: 2026-09-05 via discuss-phase inline*