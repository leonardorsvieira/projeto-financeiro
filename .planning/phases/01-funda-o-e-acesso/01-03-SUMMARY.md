# Plan 01-03 — Auth + Deploy Web (Summary)

**Plan:** 01-03 | **Wave:** 2 | **Status:** ✅ Done (aguardando checkpoint humano) | **Date:** 2026-09-06

## What Was Done

- **Feature de auth** (feature-first, conforme SKELETON):
  - `core/env.dart`: `AppEnv` com `String.fromEnvironment` para `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
  - `features/auth/domain/auth_state.dart`: `AuthStatus {unknown, unauthenticated, authenticated}` + `AuthState`.
  - `features/auth/data/auth_repository.dart`: `AuthRepository` (interface) + `SupabaseAuthRepository` (wrap do `client.auth`; stream de `onAuthStateChange`; `signUp/signIn/signOut`; email atual). — *Nota: este arquivo ficou de fora do 1º commit porque a regra `data/` do `.gitignore` raiz casava com `app/lib/features/auth/data/`; corrigido no commit `f0fc961` (padrões pessoais escopados com `/data/` na raiz).*
  - `features/auth/application/auth_controller.dart`: `StreamNotifierProvider<AuthController, AuthState>` (Riverpod 3).
  - `core/auth_errors.dart`: `friendlyAuthError` — mensagens PT-BR sem stack traces (T-03-03).
- **Rotas com redirect** (`router/app_router.dart`): go_router com splash/login/signup/home; `redirect` por sessão (`authenticated`→home; `unauthenticated`→login) via `refreshListenable` + `ref.read` do estado atual (T-03-01). Sem `usePathUrlStrategy` (URLs `#/route` — reload sempre pela raiz).
- **Telas** (UI-SPEC S1-S4): splash com spinner; login (form e-mail/senha, `obscureText` com toggle, estado loading, erro inline, link criar conta); cadastro (validação e-mail/senha≥6/confirmação, erros inline); home (AppBar "Meu Bolso", e-mail do usuário, `PopupMenu` → "Sair", placeholder Fase 2).
- **`main.dart`**: `Supabase.initialize(url, publishableKey: anon, persistSession: true)` real quando env definidas; caso contrário log (dev). `ProviderScope` + `MaterialApp.router` PT-BR.
- **Testes** (sem rede, fake repo): `test/support/fake_auth.dart` (replay de estado), `test/router_redirect_test.dart` (sem sessão→login; logado→home; deslogar→login), `test/auth_flow_test.dart` (e-mail inválido, senha curta, senhas divergentes, credenciais inválidas→msg amigável), `widget_smoke_test.dart` atualizado. **9 testes verdes, `flutter analyze` 0 issues.**
- **Deploy GH Pages** (Task 4):
  - `app/web/404.html` (fallback SPA).
  - `.github/workflows/deploy.yml`: `deploy-pages` em push na main (paths `app/**`) — checkout@v4, `subosito/flutter-action@v2` (stable), `flutter build web --release --base-href=/projeto-financeiro/` com `SUPABASE_URL/SUPABASE_ANON_KEY` de **secrets do repo** (nunca hardcoded), copia index→404.html, `.nojekyll`, `configure-pages@v5`, `upload-pages-artifact@v3`, `deploy-pages@v4`.
  - Pages habilitado via API (`gh api POST .../pages` build_type=workflow); secrets criados via `gh secret set`.
  - Workflow **success** (run `34008319301`); `https://leonardorsvieira.github.io/projeto-financeiro/` → **200**; `404.html` acessível (200 + flutter).

## Verifications Passed

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 9/9 green (sem credenciais reais; fake seed)
- [x] `flutter build web --release --base-href=/projeto-financeiro/` + dart-define OK (local e GitHub Actions)
- [x] `<base href="/projeto-financeiro/">` no build gerado
- [x] Workflow deploy-pages verdes no ref `main`
- [x] GET https://leonardorsvieira.github.io/projeto-financeiro/ → 200

## Notes / Divergences

- **`anonKey` deprecated** no supabase_flutter 2.17 → passamos a chave anon JWT no parâmetro `publishableKey` do `Supabase.initialize` (aceita ambos; sem mudança de comportamento). Troca p/ `sb_publishable_*` fica registrada p/ upgrade.
- URLs do app são `#/route` (default go_router), então reload em qualquer tela passa pela raiz — GH Pages 404 de nested path não afeta o fluxo (o `404.html` continua como fallback manual).
- Workflow usa JetBrains/yaml — sem problemas conhecidos.
- **Checkpoint humano pendente**: criar conta → login → sessão persiste → logout → redirect (ver `01-03-PLAN.md` Task 5).

## Follow-ups

- Fase 2+: habilitar `flutter_secure_storage` para a sessão (hardening, antes de dados sensíveis).
- Considerar `usePathUrlStrategy` + testes profundos de SEO/deep-link quando houver necessidade.