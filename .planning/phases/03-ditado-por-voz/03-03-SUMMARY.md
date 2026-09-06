# Plan 03-03 — Summary

**Phase:** 3 (Ditado por Voz — Core) | **Plan:** 3 of 3 | **Date:** 2026-09-06
**Status:** ✅ Implementado, deployado e validado pelo usuário

## Objetivo
Fechar o ciclo "fala → confirmação → salvar → lista (realtime)" com testes, publicar o app com a chave Gemini real (GH Pages) e validar o fluxo no site com o usuário.

## Entregue
- **Teste fim-a-fim** `ditado_flow_test.dart`: V1 (FAB → Ditar → rascunho pré-preenchido → Salvar → item na lista), V2 (correção por voz preserva merge e persiste), V3 (valor ausente bloqueia Salvar até preencher).
- **Deploy com chave real**: secret `GEMINI_API_KEY` no GitHub; `deploy.yml` com `--dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}`; `.env` local (gitignored) e `.env.example`; validação da chave contra a API; push → workflow success → **GET URL = HTTP 200**.
- **Correções pós-UAT (deploy 2)**: retry no `GeminiDitadoRepository` (até 3 tentativas, backoff 800/1600ms, em 429/500/502/503 — `esperasRetry` injetável para testes) e prompt reforçado (`gemini_prompt.dart`: categoria/forma obrigatoriamente da lista fixa, fallback "Outros"/"Outro", mapeamentos explícitos, data só se citada). Deploy 3: **modelo trocado para `gemini-3.5-flash-lite`** (o mais estável medido — ver abaixo), 81/81 testes verdes, deploy HTTP 200.
- **Checkpoint manual (usuário)**: UAT aprovado — "deu certo!". Erro persistente de 503 nas tentativas anteriores foi eliminado com a troca de modelo + retry.

## Verificação
- `flutter analyze`: **No issues found**.
- `flutter test`: **81/81 verdes** (41 novos acumulados na Fase 3).
- Workflow GH Pages success → **URL 200** em todos os deploys (3 pushes).
- UAT manual ✅ (V10..V14; latência ~3-6s no free tier).

## Estabilidade do modelo (decisão técnica)
Medição real com áudio (6 chamadas por modelo, free tier, 2026-09-06):

| Modelo | Sucesso |
|--------|---------|
| `gemini-3.5-flash` | 2/6 |
| `gemini-3.1-flash-lite` | 3/6 |
| `gemini-flash-latest` | 1/6 |
| **`gemini-3.5-flash-lite`** | **9/12 (~75%)** |

Com o retry 3x do app, a chance de falha por ditado fica ~2% (98% de sucesso). `gemini-2.5-flash` está descontinuado para chaves novas (404). Todo o stack flash está sob carga no free tier; o retry permanece como defesa. Modelo escolhido com o usuário (pedido de "uma IA mais estável"). **Custo: zero** (free tier, sem cartão).

## Fixes notórios durante a execução
- `state advance-plan` atualizado para o bin GSD novo: `node "$env:USERPROFILE\.claude\get-shit-done\bin\gsd-tools.cjs" state advance-plan` (sem args, `--pick`/`--raw` para leitura).
- Gravação da key em `.env` local + secret via `gh secret set` (padrão do `.gitignore`, key nunca versionada).
- Erros `503/429` no free tier da Gemini são transitórios — não eram falha do código; retry + modelo mais leve (lite) resolveram.

## Próximo passo
- **Fase 3 completa** → discutir/planejar **Fase 4: Vencimentos, Itens e Recorrências**. Pendência técnica de rodada anterior: instalar toolchain Android (device/emulador).