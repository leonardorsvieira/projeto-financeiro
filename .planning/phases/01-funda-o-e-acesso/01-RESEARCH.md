# Phase 1 — Research: Fundação e Acesso

**Generated:** 2026-09-05
**Answer:** "What do we need to know to PLAN Phase 1 well?"

## Context

Capability: app "Meu Bolso" inicializado em Flutter (Android + iOS + Web) com login de usuário único via Supabase Auth e sessão persistente. Requisitos: PLAT-01, PLAT-02, PLAT-03, PLAT-05.

## Decisions

### 1. Flutter SDK (Windows) — instalação

- **Versão estável atual:** Flutter 3.47 (agosto/2026, Dart 3.11). Stable é o canal recomendado (CalVer — 4 releases/ano).
- **Instalação manual:** baixar ZIP do SDK archive (`flutter_windows_<ver>-stable.zip`), extrair para path **sem espaços/caracteres especiais** — `C:\src\flutter` ou `%USERPROFILE%\develop\flutter`. Evitar `C:\Program Files`.
- **PATH:** adicionar `<flutter>\bin` ao PATH do usuário (System Properties → Environment Variables ou via PowerShell `setx`).
- **Git for Windows:** requisito (Flutter usa git internamente). Já presente nesta máquina (`git --version` OK).
- **`flutter doctor`:** verifica 8 categorias. Crítico para mobile: **Android toolchain** (Android Studio + cmdline-tools + `flutter doctor --android-licenses`) e **Chrome** (para executar no Web). iOS requer Xcode (**Mac**) — no Windows, build iOS será validado no futuro (CI/CD ou Mac); o código Flutter é multiplataforma por natureza.
- **`flutter create`:** gera projeto com `android/ ios/ web/ linux/ macos/ windows/`. Para monorepo, criar em `app/`.

### 2. Supabase Auth (email/senha) via Supabase

- **Modelo:** Supabase = Postgres + Auth + Storage + Realtime, free tier. Projeto na região **São Paulo (sa-east-1)** para latência BRL.
- **`supabase_flutter` (estável):** suporta Android/iOS/Web/MacOS/Windows.
  - `Supabase.initialize(url:, anonKey:, authOptions: FlutterAuthClientOptions(...))`.
  - Login: `supabase.auth.signInWithPassword(email:, password:)` → `AuthResponse { session, user }`.
  - Cadastro: `supabase.auth.signUp(email:, password:)`.
  - Estado: `supabase.auth.onAuthStateChange` (stream), `supabase.auth.currentUser`, `supabase.auth.signOut()`.
- **Persistência de sessão:** por padrão o `supabase_flutter` persiste via **shared_preferences**. Para maior segurança em dados sensíveis, usar `LocalStorage` customizado com **flutter_secure_storage**. (Fase 1: persistência padrão suficiente; hardening opcional.)
- **Deep links:** necessários apenas para magic link / OAuth / reset de senha. **Não** são necessários para login com e-mail/senha. Opção segura: manter "Confirm email" desabilitado (usuário único) — senão, o fluxo de confirmação exige deep link.
- **CLI Supabase:** `supabase init` (config local `supabase/config.toml`), `supabase login` (troca de token), `supabase link` (conecta ao projeto remoto), `supabase db push` (migrations). Segredos: `SUPABASE_ACCESS_TOKEN` via env.
- **Credenciais:** URL do projeto + chave anon são públicas por natureza (client-side). Mesmo assim, entram via `--dart-define`/`.env` e **nunca no git**.

### 3. Estado e navegação (Flutter)

- **Riverpod (`flutter_riverpod`):** padrão de facto para apps Flutter modernos; `ProviderScope` na raiz; providers `authControllerProvider`, `authStateProvider`. Combina bem com evento assíncrono de `onAuthStateChange`.
- **`go_router`:** rotas nomeadas, redirecionamento condicional por auth (redirect p/ `/login` se `authState != logged`). Splash de inicialização para resolver a sessão persistida antes de decidir rota.
- **Feature-first:** `lib/features/auth/`, `lib/features/home/` com `presentation/` + `domain/` + `data/`.

### 4. Deploy Web — GitHub Pages

- Hosting grátis exige repo **público** (já é). URL: `https://leonardorsvieira.github.io/projeto-financeiro/` — **baseHref = `/projeto-financeiro/`** (projeto-site).
- Opções:
  - **A) GitHub Actions nativo (recommendado):** workflow com `actions/checkout` → `subosito/flutter-action` (instala Flutter pinado do `pubspec.yaml`) → `flutter build web --base-href=/projeto-financeiro/ --release` → `actions/configure-pages` + `actions/upload-pages-artifact` (arquivo `.nojekyll` incluído) → `actions/deploy-pages`. Permissões: `permissions: contents: read, pages: write, id-token: write`; `environment: github-pages`. Habilitar Pages via Actions (deploy-pages).
  - **B)** ação `bluefireteam/flutter-gh-pages` (branch `gh-pages`) — mais simples, menos controle.
- Nota: `build/web` precisa de `.nojekyll` para evitar que o Jekyll ignore pastas com `_`.
- SPA: para rotas roteadas pelo Flutter (go_router) em Pages, o servidor retorna 404 em rota recarregada; mitigar com `web/index.html` fallback (404.html → index.html). Fase 1: hub principal é login (rota raiz/`/login`), risco baixo; aplicar fallback como boa prática.

### 5. Segurança/Privacidade (PLAT-05)

- `.gitignore` já bloqueia `.env*`, dados, planilhas, DBS.
- Fluxos: URL/anon no `.env` local + `--dart-define` no build; segredos Supabase (service_role, access token) **nunca** no repo.
- RLS: o schema de dados (fases futuras) usará RLS por `auth.uid()`. Nesta fase não existem tabelas de dados — apenas Auth.

## Validation Architecture

- **Framework de teste:** Testes unitários/widget do Flutter (`flutter_test`).
- **Quick run (após cada task):** `flutter analyze` (rápido, ~15-30s).
- **Full suite (após onda/fase):** `flutter analyze && flutter test` (widget tests de auth + build `flutter build web --release`).
- **Verificações manuais (checkpoint human-verify):** login real contra o projeto Supabase remoto (payload visual), e roda no navegador.
- **Shadow/reference:** nenhum oracle externo disponível além do Supabase live — validação de auth usa o `supabase_flutter` real contra o projeto (não mock) nos widget/integration checks críticos.

## Risks / Pitfalls

| Risk | Mitigation |
|------|-----------|
| Android toolchain ausente no Windows (Android Studio/emulador) | `flutter doctor` na execução; se faltar, registrar `user_setup` (instalar Android Studio) e validar Android build somente até `flutter build apk --debug` |
| iOS requer Mac/Xcode — não dá para buildar iOS no Windows | Código multiplataforma por padrão; validar web+Android agora, iOS futuro via Mac/CI |
| Free tier do Supabase limita envio de e-mails de confirmação/ auth | Usuário único; desabilitar "Confirm email" se conveniente (decisão em execução) |
| GH Pages: path base (`/projeto-financeiro/`) quebra assets se não setar `--base-href` | Sempre buildar com `--base-href=/projeto-financeiro/`; revisar no checkpoint |
| Persistência de sessão compartilhada via shared_preferences (não criptografada) | Fase 1 OK p/ usuário único; documentar hardening com flutter_secure_storage no SKELETON (fase 2+) |
| Sessão persistida + deep links ausentes | Email/password apenas; sem magic link → sem necessidade de deep link |
| Produtividade no terminal Windows (PowerShell 5.1) | Comandos via `flutter.bat`, workdirs explícitos, sem aliases |

## Existing Codebase Context

- Repo é **só planejamento** (`.planning/`, `CLAUDE.md`, `.gitignore`, `LICENSE`). Sem código-app ainda → padrões a definir nesta fase (SKELETON.md define contrato arquitetural para fases 2-8).
- GitHub repo: `leonardorsvieira/projeto-financeiro` (público, origin configurado).

---
*Researched: inline synthesis (websearch 2026-09-05)*