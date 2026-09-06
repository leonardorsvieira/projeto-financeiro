# Plan 03-02 — Summary

**Phase:** 3 (Ditado por Voz — Core) | **Plan:** 2 of 3 | **Date:** 2026-09-06
**Status:** ✅ Implementado e testado

## Objetivo
UX do ditado: FAB expandido com "Ditar", rota `/lancamentos/ditar`, tela de gravação push-to-talk (S7), formulário de confirmação pré-preenchido com correção por voz campo-a-campo (S8).

## Entregue
- **FAB expandido** (`lancamentos_list_screen.dart`): `floatingActionButton: Column` com `FloatingActionButton.extended(heroTag: 'ditar', icon: mic, label: 'Ditar')` → S7 ao lado do FAB `+` (heroTag 'novo', S6 manual).
- **Rotas** (`app_routes.dart`): `lancamentoDitado = '/lancamentos/ditar'`, `confirmacaoDitado = '/lancamentos/ditar/confirmacao'`; `app_router.dart` com builders S7 e S8 (S8 lê `state.extra as RascunhoLancamento`).
- **S7 `lancamento_ditado_screen.dart`**: ConsumerStatefulWidget com o círculo grande como botão (tap start/stop — D-38); AppBar "Ditar lançamento"; dica pt-BR; estados idle ("Toque para gravar") / gravando ("Toque para parar" + pulse + cronômetro) / processando ("Analisando…"); sucesso → `context.push(AppRoutes.confirmacaoDitado, extra: rascunho)`; permissão negada e erro da IA → SnackBar e volta a gravar; gravação < 0,5s → ignora (D-38).
- **S8 `confirmacao_ditado_screen.dart`**: recebe `RascunhoLancamento`, pré-preenche os 6 campos (descrição, valor bruto, categoria/forma com fallback das listas fixas, data hoje/ISO, vencimento opcional); reusa `validateDescricao`/`validateValor`/`parseValorBRLParaCentavos` da Fase 2; valor ausente → post-frame foco no campo (D-36); botão de voz por campo → grava 1 frase → `corrigirCampo(audio, rascunhoAtual)` → merge preservando o resto; barra "Toque para parar" quando gravando; Salvar (`_isSaving` anti-duplicação, desabilita campos) → `lancamentosRepositoryProvider.create` → `context.go(AppRoutes.home)`; Cancelar → pop para S7.
- **Testes**: `fake_ditado_providers.dart` (`wrapWithDitadoFakes` + `FakeRelogio`), `lancamento_ditado_screen_test.dart` (fluxo S7→S8 com "Analisando…", perm negada, erro IA, gravação curta), `confirmacao_ditado_screen_test.dart` (pré-preenchimento, merge correção voz, valor vazio+foco, salvar cria no repositório, cancelar volta, `_isSaving`). Testes existentes atualizados (`widget_smoke_test`, `lancamentos_flow_test`).

## Verificação
- `flutter analyze`: **No issues found**.
- `flutter test`: **76/76 verdes** (11 novos nesta iteração + ajustes de FAB).

## Fixes notórios durante a execução
- **Gravação fake era instantânea (< 0,5s)** → gravação sempre "ignorada" nos fakes; injetado `ditadoRelogioProvider` (relógio sobreponível) no `DitadoController` para medir duração de forma testável.
- `Focus.of` falhava no teste de foco → verificação via `EditableText.focusNode.hasFocus`.
- Cancelar no S8 dá `pop` → volta para S7 (não a lista) — expectativa de teste corrigida.
- `TextFormField` não expõe `focusNode` como getter público → assert via widget interno.

## Próximo passo
- **Plan 03-03**: `GEMINI_API_KEY` real (secret + `--dart-define` no `.github/workflows/deploy.yml`), teste de integração fim-a-fim, UAT manual e checkpoint com o usuário.