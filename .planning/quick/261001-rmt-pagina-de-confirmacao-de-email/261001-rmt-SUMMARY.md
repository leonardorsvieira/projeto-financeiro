---
status: complete
quick_id: 261001-rmt
date: 2026-10-01
---

# Quick 261001-rmt: página de confirmação de e-mail

Problema: o link "Confirm your email address" levava a `localhost` (Site URL padrão do Supabase Auth) e o celular mostrava "site não pode ser acessado". O e-mail era confirmado mesmo assim (o Supabase confirma antes de redirecionar) — verificado em `auth.users`.

- `app/web/confirmado.html`: página estática no estilo Caderneta (claro/escuro), publicada pelo GitHub Pages em `https://leonardorsvieira.github.io/projeto-financeiro/confirmado.html`. Lê o fragmento: sucesso ou "link não vale mais" (`error`/`error_code`); apaga tokens da URL; CSP sem chamadas externas; fontes do próprio build.
- Nenhuma mudança no app: o APK usa `emailRedirectTo: null` no celular → cai na Site URL.

Pendente (usuário, painel do Supabase → Authentication → URL Configuration): Site URL = página acima; Redirect URLs incluir `https://leonardorsvieira.github.io/projeto-financeiro/**`. Opcional: template "Confirm signup" em português.
