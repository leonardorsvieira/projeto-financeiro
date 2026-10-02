---
status: complete
quick_id: 261001-tc0
date: 2026-10-01
---

# Quick 261001-tc0: site quebrava ao abrir o link de confirmação

Diagnóstico (auth_logs): cadastro pelo site às 23:42:10Z, confirmado no primeiro clique (23:42:21Z, e-mail via SMTP próprio chegou em segundos). As aberturas seguintes do mesmo link (usuário + varredura de links do Gmail, IPs 172.253.x) deram `otp_expired`; o Supabase redireciona para o site com `#error=...` e o GoRouter tratava o fragmento como rota → "Page Not Found / GoException".

- `GoRouter.onException`: qualquer endereço desconhecido → splash (que leva ao login ou à home); se tiver `error=`/`error_code=`, define aviso no login ("Este link de confirmação já foi usado ou expirou...").
- `AvisoLogin.definir`.
- Testes: `test/router_link_email_test.dart` (link expirado → login com aviso; `access_token` com sessão → home).

Verificação: 295 testes ok; analyze só com os 9 infos antigos.

## Rodada 2 (mesmo dia)

Depois do `onException`, o site passou a ficar preso no splash ao abrir `?error=...otp_expired`: o supabase_flutter emite ERRO no `onAuthStateChange` ao ler esse endereço e o `StreamNotifier` ficava em erro (status desconhecido).

- `tolerarErrosDeSessao` (auth_repository.dart): erro do stream → estado real da sessão (`currentSession`); sessão ativa não é derrubada. Testes em `test/features/auth/tolerar_erros_sessao_test.dart`.
- `emailRedirectTo` sempre `urlConfirmacaoEmail` (confirmado.html), também na web.
- confirmado.html: "Tudo certo! Seu cadastro foi salvo." + voltar ao app e fazer login (pedido do usuário).

298 testes ok.
