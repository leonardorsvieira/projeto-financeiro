# Plan 01-02 — Supabase (Summary)

**Plan:** 01-02 | **Wave:** 1 | **Status:** ✅ Done | **Date:** 2026-09-06

## What Was Done

- **Supabase CLI 2.116.0** instalado via binário do GitHub Releases (`C:\Users\leona\AppData\Local\Programs\Supabase\supabase.exe`, adicionado ao PATH do usuário) — winget e choco não tinham o pacote.
- `supabase init` na raiz → `supabase/config.toml` com `project_id` ajustado para o ref remoto.
- **Organização** criada via CLI: `Leonardo Vieira` (id `mbrirdfkshncxiahgafv`) — a conta do usuário ainda não tinha org.
- **Projeto remoto** `meubolso` criado na região **sa-east-1 (São Paulo)** — ref **`tkfhthotspehsgvmpsjm`**, status **ACTIVE_HEALTHY**.
- `supabase link --project-ref tkfhthotspehsgvmpsjm` → vinculado (confirmado por `supabase status` → linked_project).
- **`.env`** criado na raiz (fora do git) com `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_PUBLISHABLE_KEY` (chave `sb_publishable_*`, necessária pois `anonKey` está deprecated no supabase_flutter 2.17).
- **`.env.example`** commitado com placeholders + `!.env.example` no `.gitignore` raiz.
- **Auth por e-mail habilitado via Management API** (PATCH `/v1/projects/{ref}/config/auth`):
  - `external_email_enabled = true`
  - `mailer_autoconfirm = true` (equivale a desabilitar "Confirm email" — usuário único, sem etapa de confirmação)
- `.gitignore` raiz já protegia `.env` / `.env.*`; reforçado `.env` em `supabase/.gitignore`.

## Verifications Passed

- [x] `supabase --version` → 2.116.0
- [x] `supabase status` → mostra linked_project (ref/name/org corretos); erro de docker é esperado (pool local não usado — só remoto)
- [x] `.env` com 3 variáveis não vazias
- [x] `git check-ignore .env` → retorna `.env` (protegido)
- [x] `git status --short` **não** lista `.env` nem `supabase/.env`
- [x] Email provider: `external_email_enabled=True`, `mailer_autoconfirm=True`

## Notes / Divergences

- Região solicitada **sa-east-1 aplicada** (sem divergência; CLI aceitou).
- O campo antigo `external_email_otp_confirm_required` não existe mais no schema da API — o equivalente atual é **`mailer_autoconfirm`** (atualizado no RESEARCH para a Fase 2+).
- `service_role` key **nunca** escrita em disco/repo; apenas lida da API para inspeção.
- **Ação do usuário:** revogar o Personal Access Token após o fim da Fase 1 se desejar (Dashboard → Account → Access Tokens).

## Follow-ups

- Plan 01-03 vai usar `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` (ou a publishable key) no build web e wire do auth real.
- Hardening (Fase 2+): flutter_secure_storage para sessão quando existirem dados sensíveis.