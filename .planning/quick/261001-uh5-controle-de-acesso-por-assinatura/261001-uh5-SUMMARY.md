---
phase: quick-261001-uh5
plan: 01
subsystem: acesso
status: complete
tags: [supabase, rls, edge-functions, riverpod, go_router, assinatura]
requires: []
provides:
  - "Migration 20261001220000_controle_de_acesso.sql (NÃO aplicada): administradores, acessos, eh_admin(), acesso_ativo(), 9 policies RESTRICTIVE, hook opcional"
  - "_shared/seguranca.ts: acessoAtivo() + hojeEmBrasilia(); preambulo devolve 403 acesso_inativo antes da cota (NÃO publicado)"
  - "pluggy-webhook ignora dono sem acesso ativo (NÃO publicado)"
  - "Feature app/lib/features/acesso: portão /sem-acesso, aviso de vencimento no Resumo, tela Clientes e acessos"
affects: [router, dashboard, home, ditado, open_finance, auth_errors]
tech-stack:
  added: []
  patterns:
    - "Servidor como fonte da verdade (RLS RESTRICTIVE + Edge Functions); o portão do app é só UX"
    - "Falha aberta só na primeira consulta de status; recarga com erro mantém o último status"
key-files:
  created:
    - supabase/migrations/20261001220000_controle_de_acesso.sql
    - app/lib/features/acesso/domain/acesso.dart
    - app/lib/features/acesso/domain/acesso_repository.dart
    - app/lib/features/acesso/domain/regras_acesso.dart
    - app/lib/features/acesso/data/supabase_acesso_repository.dart
    - app/lib/features/acesso/application/acesso_providers.dart
    - app/lib/features/acesso/presentation/contato_vendedor.dart
    - app/lib/features/acesso/presentation/sem_acesso_screen.dart
    - app/lib/features/acesso/presentation/aviso_vencimento_acesso.dart
    - app/lib/features/acesso/presentation/admin_acessos_screen.dart
    - app/lib/features/acesso/presentation/acesso_dialog.dart
    - app/test/support/fake_acesso_repository.dart
    - app/test/core/auth_errors_test.dart
    - app/test/features/acesso/ (regras_acesso, acesso_providers, portao_acesso, aviso_vencimento_acesso, admin_acessos_screen, menu_admin)
  modified:
    - supabase/functions/_shared/seguranca.ts
    - supabase/functions/pluggy-webhook/index.ts
    - app/lib/core/edge_function.dart
    - app/lib/core/auth_errors.dart
    - app/lib/features/ditado/data/gemini_ditado_repository.dart
    - app/lib/features/open_finance/data/pluggy_open_finance_service.dart
    - app/lib/router/app_router.dart
    - app/lib/features/home/domain/app_routes.dart
    - app/lib/features/dashboard/presentation/dashboard_screen.dart
    - app/lib/features/dashboard/presentation/home_screen.dart
    - app/test/support/fake_auth.dart
    - app/test/support/fake_wrappers.dart
    - app/test/support/fake_ditado_providers.dart
    - app/README.md
decisions:
  - "Conta vencida mantém SELECT (exportar CSV) e excluir-conta (LGPD); só INSERT/UPDATE/DELETE, ditado e pluggy são travados"
  - "Hook Before User Created é opcional: o sistema funciona igual sem ele"
  - "Erro na verificação de acesso nas Edge Functions falha fechado (503); no app, na primeira consulta, falha aberta (o servidor protege)"
metrics:
  tasks: 3
  commits: 3
  tests: "360 (todos verdes)"
completed: 2026-10-01
---

# Quick 261001-uh5: Controle de acesso por assinatura

Só quem o dono liberou, dentro da validade, usa o Meu Bolso: o servidor (migration + Edge Functions) decide e o app só traduz isso em portão `/sem-acesso`, aviso de vencimento e tela de administrador.

## O que foi entregue

**Task 1 (04e52e4) — servidor e mensagens do app**
- Migration `20261001220000_controle_de_acesso.sql` (não aplicada): `administradores` (só SELECT da própria linha; `revoke` de escrita/truncate), `acessos` (e-mail normalizado, `valido_ate` nulo = sem prazo), `eh_admin()` e `acesso_ativo()` (`security definer`, `search_path = ''`, EXECUTE só para `authenticated`), policies de `acessos` (cada um lê a própria linha; só admin lista e escreve), 9 policies `AS RESTRICTIVE` (INSERT/UPDATE/DELETE em `lancamentos`, `metas`, `investimentos`; policies `*_own` e SELECT intactos) e `hook_antes_de_criar_usuario` (EXECUTE só para `supabase_auth_admin`). Sem e-mails nem ids.
- `_shared/seguranca.ts`: `acessoAtivo()` (mesma regra do SQL) e `hojeEmBrasilia()`; `preambulo` devolve 403 `acesso_inativo` antes de `consumirCota` e 503 `verificacao_acesso_falhou` se a checagem falhar. `ditado`, `pluggy` e `excluir-conta` (`index.ts`) intocados.
- `pluggy-webhook`: confere o acesso do dono (e-mail via `auth.admin.getUserById`) antes da cota e da importação; log sem e-mail/id/valores.
- App: `mensagemAcessoInativo`/`ehAcessoInativo` (`core/edge_function.dart`), tratados no ditado (sem retry nem troca de modelo) e no Open Finance (o 403 `rota_nao_permitida` segue como antes); `friendlyAuthError` traduz a recusa do hook.
- `app/README.md`: seção "Controle de acesso (assinatura)" com seed por SQL (placeholder), hook e ordem de implantação.

**Task 2 (d5738af) — portão no app**
- `AcessoRepository` + `SupabaseAcessoRepository` (RPCs `acesso_ativo`/`eh_admin` + linha própria em `acessos`, timeout de 10 s; `listar/salvar/renovar/bloquear/remover` traduzem falhas em `AcessoException`).
- Regras puras em `regras_acesso.dart` (normalização, `novaValidade` a partir do maior entre hoje e a validade, `validadeDeBloqueio`, rótulos, aviso, formatos).
- `statusAcessoProvider` + `decidirAcesso` (falha aberta só na primeira consulta; recarga com erro mantém o último status).
- Router: redirect `aguardando` (splash) / `bloqueado` (só `/sem-acesso`, `/privacidade-e-dados`, `/privacidade`, `/termos`) / `liberado`; status reavaliado no login e ao voltar ao app (no máx. 1x/min).
- `SemAcessoScreen` (Falar com o vendedor, Meus dados, "Já renovei — verificar de novo", Sair) e `AvisoVencimentoAcesso` (0 a 5 dias) no topo do Resumo; análise por IA mostra a mensagem clara de acesso inativo.
- Fakes: `FakeAcessoRepository` (padrão ativo) injetado em `wrapWithFakes`, `wrapWithFake` e `wrapWithDitadoFakes`; nenhum teste existente precisou mudar.

**Task 3 (f743939) — administrador**
- `AdminAcessosScreen` ("Clientes e acessos"): lista, busca, novo/editar (`acesso_dialog.dart`), renovar +30, bloquear e remover com confirmação, mensagens de erro em SnackBar.
- Rota `/admin/acessos` (não admin vai à home; deslogado vai ao login) e item "Clientes e acessos" no menu só para admin.

## Verificação

- `cd app && flutter test`: **360 testes, todos verdes** (inclui 55 novos de acesso + 3 de auth_errors + 3 de mensagens de acesso inativo).
- `cd app && flutter analyze`: **9 infos, todas `deprecated_member_use` PRÉ-EXISTENTES** em arquivos que este plano não tocou (`conectar_banco_dialog.dart`, `pdf_report_service.dart`, `theme_selector_dialog.dart`). Nenhum issue novo. (Não é literalmente "No issues found" por causa delas; fora de escopo.)
- Gates de grep do Task 1 (9 `as restrictive`, nenhum e-mail/uuid na migration, nenhuma referência às tabelas apagadas, `search_path = ''` nas 3 funções, `supabase_auth_admin`, `acesso_inativo`, `acessoAtivo(`, `excluir-conta` sem `preambulo(`/`acessoAtivo(`): todos passaram.
- NÃO verificado por execução: o SQL (sem Postgres local) e o TypeScript (sem Deno local) — conferidos só por grep e revisão linha a linha.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ref.listen` inferido como `dynamic` no `_AuthListenable`**
- **Found during:** Task 2 (portão_acesso_test: NoSuchMethodError `isLoading`)
- **Issue:** `late final ProviderSubscription _subAcesso` (tipo cru) fazia o `listen` inferir `T = dynamic`, então `atual.isLoading` (extension) falhava em runtime.
- **Fix:** `listen<AsyncValue<StatusAcesso?>>(...)` explícito.
- **Files modified:** `app/lib/router/app_router.dart`
- **Commit:** d5738af

**2. [Rule 3 - Blocking] Riverpod 3 pausa provider sem ouvinte em `ProviderContainer` de teste**
- **Found during:** Task 2 (acesso_providers_test travava em `container.read(authControllerProvider.future)`)
- **Fix:** `container.listen(...)` para `authControllerProvider` e `statusAcessoProvider` no helper do teste (só teste; código de produção inalterado).
- **Commit:** d5738af

### Ajustes menores

- `python` não existe no ambiente: as edições dos testes foram feitas com a ferramenta Edit.
- `dart format` aplicado só em arquivos NOVOS do plano; arquivos existentes editados não foram reformatados (diff mínimo).
- O plano prescreve e-mails sintéticos nos testes (`ana@cliente.com`, `leo@meubolso.com` etc.); são fixtures, não dados reais. `emailVendedor` apenas reaproveita a constante `emailPrivacidade` que já existia no repositório.
- STATE.md/ROADMAP.md não foram alterados (a instrução do orquestrador manteve `.planning/` fora dos commits).

## Known Stubs

Nenhum.

## Threat Flags

Nenhum além do mapeado em `<threat_model>` (T-uh5-01..11).

## Pendências para o orquestrador (nesta ordem)

1. Aplicar `supabase/migrations/20261001220000_controle_de_acesso.sql` no projeto `tkfhthotspehsgvmpsjm` (se a versão registrada no remoto for outra, renomear o arquivo para casar).
2. Na MESMA sessão, logo em seguida (senão todo mundo perde a escrita): seed por SQL — dono em `administradores`; as 3 contas existentes em `acessos` com `valido_ate` nulo. Nada disso em arquivo versionado. (Há um arquivo não rastreado `supabase/ativar_controle_de_acesso.local.sql` na árvore, que NÃO foi criado por esta execução e NÃO foi commitado.)
3. Só então publicar `ditado`, `pluggy` (com verificação de JWT) e `pluggy-webhook` (com as mesmas flags de hoje) — todas importam `_shared/seguranca.ts`; publicar antes da migration daria 503 para todos.
4. Push da `main` (web) e novo APK: o app é seguro em qualquer ordem (sem a RPC, o portão libera e nada muda).
5. Opcional: o dono ativa o hook Before User Created no Dashboard (Authentication → Hooks → Postgres → `public.hook_antes_de_criar_usuario`).

## Self-Check: PASSED

- Todos os arquivos criados existem (conferido com `[ -f ]`).
- Commits encontrados no log: 04e52e4, d5738af, f743939; todos terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; nenhuma deleção de arquivo; nada publicado (sem push, sem `db push`, sem deploy).

## Pós-execução (orquestrador, 2026-10-01/02)

- Revisão manual da migration e das Edge Functions: ok (SELECT livre para LGPD, escrita exige acesso ativo, ninguém se libera sozinho, falha da checagem no servidor → 503).
- **Aplicar a migration foi BLOQUEADO pelo classificador do auto mode** (produção), apesar da autorização geral do usuário. Não contornado.
- Por isso as Edge Functions `ditado`, `pluggy`, `pluggy-webhook` **não foram publicadas** (sem a migration responderiam 503 a todos).
- Criado `supabase/ativar_controle_de_acesso.local.sql` (fora do git via `*.local.sql`): migration + dono em `administradores` + todas as contas atuais em `acessos` sem prazo + registro em `supabase_migrations.schema_migrations` (versão 20261001220000), tudo numa transação.
- Push e APK feitos: o app libera a UX quando a RPC não existe, então funciona igual até a ativação.

Pendente (usuário): rodar o script no SQL Editor; depois publicar `ditado`, `pluggy`, `pluggy-webhook`; opcional ativar o hook Before User Created.

## Ativação (2026-10-02)

- Usuário rodou `ativar_controle_de_acesso.local.sql`: tabelas e travas criadas, 1 administrador, 3 contas liberadas sem prazo, versão 20261001220000 registrada.
- Verificado no banco (simulando JWT, só leitura): sem acesso → `acesso_ativo=false`; dono → admin; conta antiga → ativa. Hook recusa e-mail não liberado (403) e aceita liberado (case-insensitive).
- Publicadas: `ditado` v4 e `pluggy` v11 (JWT obrigatório), respondem 401 sem login.
- `pluggy-webhook` (sem JWT): deploy BLOQUEADO pelo classificador do auto mode — pendente do usuário: `supabase functions deploy pluggy-webhook --no-verify-jwt --project-ref tkfhthotspehsgvmpsjm`. Até lá a versão antiga importa transações também para contas vencidas (só leitura do banco do próprio dono; impacto baixo).

- 2026-10-02: usuário publicou `pluggy-webhook` pela CLI (`supabase login` + deploy `--no-verify-jwt`): v5, verify_jwt=false, responde 200 `{"ignorado":true}` a aviso inválido. Controle de acesso 100% no ar.
