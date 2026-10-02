---
status: awaiting-verification
trigger: "Botão \"Conectar meu.pluggy.ai\" em outro aparelho (conta de cliente) mostra \"Erro ao abrir autorização: Exception: Não foi possível iniciar a conexão com o meu.pluggy.ai (Status 400)\""
created: 2026-10-02
updated: 2026-10-02
---

# Debug: meu-pluggy-400-cliente

## Symptoms

- **Expected:** tocar em "Conectar meu.pluggy.ai" abre a autorização do Meu Pluggy no navegador.
- **Actual:** snackbar vermelho "Erro ao abrir autorização: Exception: Não foi possível iniciar a conexão com o meu.pluggy.ai (Status 400)".
- **Error:** status 400 vindo da Pluggy no `POST /items` (connectorId 200).
- **Timeline:** visto em 2026-10-02 ~13:48 (Brasília), em conta de cliente com acesso ativo; os 4 items do dono foram registrados em 2026-09-29.
- **Reproduction:** conta de cliente → Bancos e Open Finance → "Conectar meu.pluggy.ai".

## Current Focus

- hypothesis: a Pluggy recusa o `POST /items` do conector 200 para esta conta; o motivo está no corpo do erro, que a função não registra.
- next_action: instalar o APK 1.2.1 no aparelho do cliente, conectar o Meu Pluggy pelo widget, voltar ao app e sincronizar; conferir no log `item_registrado` do `pluggy-webhook` e a linha em `pluggy_items`.

## Evidence

- timestamp: 2026-10-02T16:48:52Z–16:51:17Z — logs da função `pluggy`: 6x `{"rota":"/items","status":400,"codigo":400}` e `{"rota":"resposta POST","status":400}`. Preâmbulo passou (sem 401/403/429): login, e-mail confirmado, acesso ativo e cota OK.
- timestamp: 2026-10-02 — a mesma sessão loga `{"itens":[]}` (usuário sem items em `pluggy_items`) → é conta de cliente, não a do dono.
- timestamp: 2026-10-01T17:33Z–2026-10-02T16:50Z — `GET /items (listagem)` responde 401 em todas as 80 chamadas: a Pluggy não permite listar items com a API key. Consequência: items que um cliente cria pelo widget Connect (sem o item já criado pelo app) nunca entram em `pluggy_items`.
- código: `app/lib/features/open_finance/data/pluggy_open_finance_service.dart` `iniciarConexaoMeuPluggyDireta()` manda `{connectorId: 200, parameters: {}}`; a função `pluggy` acrescenta `clientUserId` e `webhookUrl`.

- timestamp: 2026-10-02T16:58:33Z — com `pluggy` v12 registrando a mensagem: `{"rota":"/items","status":400,"mensagem":"Free subscription can only create items through our Connect Widget | CREATE_ITEMS_API_FREE_DISABLED"}`.
- timestamp: 2026-09-29T10:15–10:17Z — os 4 items Meu Pluggy do dono geraram `item/created` no `pluggy-webhook` segundos após a criação: a Pluggy entrega avisos ao webhookUrl definido no connect token/item.

## Eliminated

- hypothesis: falha de login/acesso/cota no app — a função passou do preâmbulo e chegou à Pluggy.

## Resolution

- root_cause: a conta Pluggy está no plano grátis, que só cria items pelo widget Connect; o botão "Conectar meu.pluggy.ai" criava o item por `POST /items` (400 CREATE_ITEMS_API_FREE_DISABLED). Agravante: a Pluggy não lista items (`GET /items` 401), então items criados pelo widget nunca eram vinculados ao cliente.
- fix: app abre o widget com connect token no conector 200 (`urlConexaoMeuPluggy`), sem item provisório local; `pluggy-webhook` (v6) registra item sem dono pelo `clientUserId` lido na Pluggy (só o proxy define esse campo, sempre com o uid do JWT); `pluggy` registra a mensagem de erro da Pluggy (v12) e perdeu a listagem inútil (versão do repo ainda não publicada — o classificador bloqueou; o usuário publica). App 1.2.1+6.
- verification: `flutter analyze` sem avisos novos; `flutter test` 359 passando; webhook v6 ignora item desconhecido (200 `{"ignorado":true}`). Falta o teste real no aparelho do cliente.
- files_changed: app/lib/features/open_finance/data/pluggy_open_finance_service.dart, app/lib/features/open_finance/presentation/open_finance_screen.dart, app/lib/features/open_finance/presentation/widgets/conectar_banco_dialog.dart, app/test/features/open_finance/pluggy_open_finance_service_test.dart, app/pubspec.yaml, supabase/functions/pluggy/index.ts, supabase/functions/pluggy-webhook/index.ts, CLAUDE.md
