---
quick_id: 260928-n3q
status: complete
date: 2026-09-28
---

# Resumo — Endurecimento de segurança multiusuário

## Feito

- **Segredos fora do app:** removido o client id/secret da Pluggy hardcoded e o formulário que guardava credenciais no aparelho; `GEMINI_API_KEY` saiu de `env.dart`, `build_apk.ps1`, `deploy.yml`, `build-ios.yml`. Bundle web novo verificado sem segredos.
- **Edge Functions** (deployadas, `verify_jwt`): `ditado` (proxy Gemini com allowlist de modelos, limite de 10 MB, cota 150/dia) e `pluggy` (proxy com allowlist de rotas, `clientUserId` = usuário, ownership em `pluggy_items`, cota 500/dia). `_shared/seguranca.ts`: exige e-mail confirmado, CORS com allowlist.
- **Migration `20260928195702_seguranca_multiusuario`** (aplicada): `pluggy_items`, `uso_diario`, `consumir_cota()` só para service_role, `anon` sem privilégios no schema public. Verificado: anon recebe `permission denied`; funções retornam 401 sem login.
- **Isolamento de sessão no app:** `_SessaoIsolada` (main.dart) apaga SharedPreferences/notificações/widget e recria o `ProviderContainer` quando o usuário sai, a sessão expira ou outra conta entra (antes, streams do usuário anterior ficavam em memória).
- **Plataforma/CI:** Android `allowBackup=false`; CSP + `no-referrer` no `web/index.html` (verificado no navegador sem violações); workflow `secret-scan.yml` (gitleaks).
- **Docs:** CLAUDE.md, PROJECT.md, README, `.env.example`.

## Verificação

- `flutter test`: 231 passando (novos: limite diário do ditado, proxy Pluggy sem X-API-KEY, sem login não chama servidor, limpeza local).
- `flutter analyze`: nenhum erro/aviso novo (restam infos de deprecação pré-existentes).
- `get_advisors` security: só `uso_diario` sem policy (intencional) e leaked password protection (ação do usuário).

## Pendente (usuário)

Rotacionar secret da Pluggy; `supabase secrets set ...`; exigir confirmação de e-mail + leaked password protection; revisar as 3 contas; apagar secret `GEMINI_API_KEY` do GitHub; revogar PAT do Supabase citado no STATE (sessão de 2026-09-07).

## Continuação (2026-09-29) — Open Finance

- Proxy/webhook: `/v2/transactions` (o `/transactions` antigo dá 410), webhook por conexão (`webhookUrl`), remoção real de conexões, cota Pluggy 3000/dia.
- Sincronização automática (app aberto) + `pluggy-webhook` (app fechado); índice único `lancamentos_pluggy_unico` contra duplicação.
- Regras de dinheiro: sinal invertido no cartão, pagamento de fatura ignorado, categorias neutras (transferência entre contas / investimento) fora do saldo (`lancamentosContabeisProvider`).
- Dados: importações erradas movidas para `lancamentos_backup_pluggy` (só servidor) e reimportadas; 26 repetidos (data+valor+tipo+descrição) movidos para a reserva.
- UI: "Gastos por Meio de Pagamento" só do mês selecionado; cartão "Captura em Tempo Real" escondido (nunca foi implementado).
- Pendente (usuário): decidir sobre 78 lançamentos manuais com gêmeo importado; apagar a reserva depois de conferir.
