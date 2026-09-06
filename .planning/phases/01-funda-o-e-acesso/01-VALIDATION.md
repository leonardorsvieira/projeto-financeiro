---
phase: 01
slug: funda-o-e-acesso
status: in_progress
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-05
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) + `flutter analyze` |
| **Config file** | `app/pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && flutter test && flutter build web --release` |
| **Estimated runtime** | ~60-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | PLAT-02 | T-01-01 / — | App Flutter orchestrado p/ Android, iOS, Web | build | `flutter build web --release` | ✅ W0 | ✅ green |
| 01-01-02 | 01 | 1 | PLAT-02 | T-01-02 / — | tema PT-BR + home placeholder | widget | `flutter test` | ✅ W0 | ✅ green |
| 01-02-01 | 02 | 1 | PLAT-05 | T-02-01 | segredos fora do git; `.env*` ignorado | config | `git check-ignore .env` | ✅ W1 | ✅ green |
| 01-02-02 | 02 | 1 | PLAT-01 | T-02-02 | Supabase inicializado p/ auth | unit | `flutter test` (init smoke no plan 01-03) | ✅ W1 | ⬜ pending (runtime no 01-03) |
| 01-03-01 | 03 | 2 | PLAT-01 | T-03-01 | login/cadastro chamam Supabase e só navegam com sucesso | widget | `flutter test` | ✅ W2 | ✅ green |
| 01-03-02 | 03 | 2 | PLAT-01 | T-03-02 | sessão persiste entre aberturas | widget + manual | `flutter test` + checkpoint | ✅ W2 | ✅ green (aprovado 2026-09-06) |
| 01-03-03 | 03 | 2 | PLAT-03 | T-03-03 | build web deployado no GH Pages | deploy | `gh pages` URL 200 | ✅ W2 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `app/test/` — stubs de widget test para auth/home (criados no plan 01-01)
- [ ] `flutter analyze` sem erros desde o primeiro commit
- [ ] Framework `flutter_test` já incluso pelo `flutter create`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Login real contra o Supabase remoto (criar conta + entrar) | PLAT-01 | Necessita do projeto remoto + credenciais reais do usuário | Abrir o app (web) e criar conta com e-mail/senha; sair e entrar de novo |
| Sessão persiste ao fechar/reabrir | PLAT-01 | Comportamento de aplicação real (persistência local) | Fechar a aba, reabrir → deve estar logado |
| App abre nos 3 alvos | PLAT-02 | Emulador de Android + web | `flutter run -d chrome` e, se Android toolchain OK, `flutter run -d emulador` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-06 (checkpoint humano 01-03 Task 5 — conta criada, sessão persistiu, logout/redirect OK)