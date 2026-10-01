---
phase: quick-261001-l9o
plan: 01
subsystem: privacidade / auth / edge-functions
status: complete
tags: [lgpd, privacidade, termos-de-uso, exclusao-de-conta, edge-function, flutter]
requires:
  - auth (AuthState/AuthRepository/AuthController)
  - core/edge_function.dart
  - supabase/functions/_shared (seguranca.ts, pluggy.ts)
provides:
  - Política de Privacidade e Termos de Uso dentro do app (rotas públicas /privacidade e /termos)
  - Aceite obrigatório no cadastro (termos_versao + termos_aceitos_em nos metadados)
  - Portão bloqueante de re-aceite para contas existentes (/aceite-termos)
  - Tela "Privacidade e dados" (/privacidade-e-dados) com exportação CSV, contato e exclusão da conta
  - Edge Function excluir-conta (escrita, NÃO publicada)
affects:
  - app_router.dart (redirect), signup_screen.dart, login_screen.dart, home_screen.dart, main.dart
tech-stack:
  added: []
  patterns:
    - Dados do controlador num único arquivo (controlador.dart); textos legais como dados Dart const
    - Aviso entre sessões via AvisoProximaSessao (estático) + avisoLoginProvider no container novo
key-files:
  created:
    - app/lib/features/privacidade/domain/{controlador,documento_legal,textos_legais,aceite_termos,exclusao_conta_repository}.dart
    - app/lib/features/privacidade/data/supabase_exclusao_conta_repository.dart
    - app/lib/features/privacidade/application/privacidade_providers.dart
    - app/lib/features/privacidade/presentation/{documento_legal_screen,destaques_privacidade,aceite_termos_screen,privacidade_dados_screen,excluir_conta_dialog}.dart
    - app/lib/features/auth/application/aviso_login.dart
    - supabase/functions/excluir-conta/index.ts
    - app/test/features/privacidade/*_test.dart (6 arquivos)
    - app/test/support/fake_exclusao_conta_repository.dart
  modified:
    - app/lib/features/auth/{domain/auth_state,data/auth_repository,application/auth_controller,presentation/signup_screen,presentation/login_screen}.dart
    - app/lib/features/home/domain/app_routes.dart
    - app/lib/router/app_router.dart
    - app/lib/theme/icones.dart
    - app/lib/main.dart
    - app/lib/features/dashboard/presentation/home_screen.dart
    - app/lib/features/seguranca/application/limpeza_local.dart
    - app/test/support/fake_auth.dart
    - app/test/auth_flow_test.dart
decisions:
  - nomeControlador continua o placeholder '[RESPONSÁVEL]'; teste pulado lembra de preencher antes do APK comercial
  - Edge Function excluir-conta escrita e commitada, mas NÃO publicada (deploy fica com o orquestrador)
metrics:
  tasks: 3
  commits: 3
  completed: 2026-10-01
---

# Quick 261001-l9o: LGPD, privacidade, termos e exclusão de conta

Política de Privacidade e Termos de Uso dentro do app, aceite obrigatório no cadastro, re-aceite bloqueante para contas existentes, tela "Privacidade e dados" e exclusão de conta (Edge Function `excluir-conta` + cliente), tudo com testes e sem dependências novas.

## O que foi entregue

**Task 1 — `de06bca` feat(privacidade): política de privacidade e termos de uso no app**
- `controlador.dart` com `nomeControlador` (placeholder), `emailPrivacidade`, `versaoDocumentos = '2026-10-01'`; nenhum outro arquivo de `app/lib` contém o e-mail literal nem `RESPONSÁVEL`.
- `documento_legal.dart` (`BlocoLegal` selado, `SecaoLegal`, `DocumentoLegal.textoCompleto`, `formatarVersao`) e `textos_legais.dart` (Política em 12 seções, Termos em 13, 3 destaques). Textos descrevem os fluxos reais (Supabase São Paulo, Gemini no plano gratuito, Pluggy, dados só no aparelho, biometria do sistema, contagem diária, registros de acesso); Termos sem isenção total, com CDC preservado e foro do domicílio do consumidor.
- `DocumentoLegalScreen` (Fraunces/Inter, "Versão de 01/10/2026", `SelectionArea`, voltar para `/home` quando não há histórico); rotas públicas `/privacidade` e `/termos`; ícones `privacidade`, `termos`, `excluirConta`.

**Task 2 — `7f33321` feat(privacidade): aceite dos termos no cadastro e re-aceite**
- `AuthState.termosVersao` (em `==`/`hashCode`), `AuthRepository.signUp(..., metadados)` + `aceitarTermos`, `AuthController.signUp` sempre leva `metadadosDeAceite()`.
- Cadastro: `DestaquesPrivacidade(compacto)`, `CheckboxListTile` de aceite, links para os documentos via `push`; botão "Criar conta" só habilita com a caixa marcada.
- `AceiteTermosScreen` (bloqueante, "Aceitar e continuar" / "Sair"); redirect do router leva conta sem aceite vigente à tela de aceite, liberando só `/aceite-termos`, `/privacidade` e `/termos`.
- `FakeAuthRepository` normaliza estados autenticados sem versão para a vigente (os 8 testes antigos seguem sem mudança); `termosEmDia: false` testa o portão.

**Task 3 — `00201b1` feat(privacidade): tela privacidade e dados e exclusão de conta**
- Edge Function `supabase/functions/excluir-conta/index.ts`: só POST, 401 sem JWT válido, id vem só de `usuarioAutenticado` (corpo ignorado), desconecta bancos na Pluggy em best effort, `admin.auth.admin.deleteUser(usuario.id)` (cascata nas tabelas), logs sem dados pessoais, erro genérico `falha_ao_excluir`; não consome cota.
- Cliente `SupabaseExclusaoContaRepository` (POST `{}`, timeout 30 s, sem retry; 401 -> mensagem de sessão; demais falhas -> mensagem genérica), `exclusaoContaRepositoryProvider`, `compartilharArquivoProvider`, `limparDadosLocaisProvider`.
- `PrivacidadeDadosScreen` (política, termos, exportar CSV com `utf8.encode`, mailto, excluir conta), `excluir_conta_dialog.dart` (digitar EXCLUIR; botão desabilitado durante o envio; erro mantém o usuário logado), item "Privacidade e dados" no menu da home.
- Pós-exclusão: limpa dados locais, `AvisoProximaSessao.definir('Conta excluída.')`, signOut, `context.go(login)`; `main.dart` entrega o aviso só ao container novo e `LoginScreen` mostra a SnackBar uma vez.

## Verificação

- `flutter test` (suíte inteira): **291 passaram, 1 pulado** (o teste do nome do controlador, com o motivo "preencher nomeControlador antes do APK comercial"). Nenhuma falha.
- `flutter analyze`: **9 issues, todas `info` `deprecated_member_use` pré-existentes** em arquivos que este plano não tocou (`conectar_banco_dialog.dart`, `pdf_report_service.dart`, `theme_selector_dialog.dart`). Nenhum issue em arquivo novo ou alterado. Não é "No issues found" por causa dessas 9 pré-existentes.
- `grep -rln "RESPONSÁVEL" app/lib` -> só `controlador.dart`; `grep "leonardorodriguesv99" app/lib` -> só `controlador.dart`; sem `Icons.`/`Icon(` em `features/privacidade`; `grep -c "deleteUser(usuario.id)"` = 1.
- `deno` não está instalado nesta máquina: `deno check supabase/functions/excluir-conta/index.ts` foi **pulado**. A função só foi revisada à mão.

## Deviations from Plan

None - plano executado como escrito. Ajustes menores de implementação, sem mudar comportamento: `controlador.dart` usa comentários `//` no cabeçalho (um `///` solto gerava o lint `dangling_library_doc_comments`); no teste do cadastro com links, voltar usa `find.byTooltip('Voltar')` (o `pageBack()` do Flutter não achou o botão com o tema do app); testes de portão/exclusão usam `ensureVisible` porque a tela de teste (800x600) é mais baixa que o conteúdo. Um teste extra (links do cadastro preservam o formulário) foi adicionado em `auth_flow_test.dart`.

## Known Stubs

- `nomeControlador = '[RESPONSÁVEL]'` em `app/lib/features/privacidade/domain/controlador.dart` é placeholder intencional. Os textos legais mostram esse marcador até o nome real ser preenchido; o teste "nome do controlador preenchido para o APK comercial" fica pulado e sinaliza a pendência. **Preencher antes do APK comercial.**

## Pendências para o orquestrador / operador

1. **Deploy da Edge Function (NÃO feito):** `supabase functions deploy excluir-conta` (com verificação de JWT, que é o padrão). Sem o deploy, "Excluir minha conta" no app devolve a mensagem genérica de erro (a função remota não existe).
2. Preencher `nomeControlador` em `controlador.dart`.
3. Contas existentes (dono e convidados) vão ver a tela de re-aceite no próximo login/abertura, pois não têm `termos_versao`.
4. Validar em aparelho: mailto, folha de compartilhamento do CSV (usa `Printing.sharePdf`, como o relatório comparativo) e a exclusão ponta a ponta contra o Supabase real.

## Threat Flags

Nenhuma superfície nova fora do `<threat_model>` do plano (T-l9o-01..09 cobertas: id só do JWT, 401 sem JWT, logs sem dados pessoais, só POST/Bearer/CORS por allowlist, confirmação EXCLUIR sem retry, limpeza local antes do signOut).

## Self-Check: PASSED

- Arquivos criados conferidos (14 principais encontrados).
- Commits `de06bca`, `7f33321`, `00201b1` existem no `main`, todos com o trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `.claude/` e `.planning/` fora dos commits; nada foi publicado ou enviado (sem push, sem deploy).
