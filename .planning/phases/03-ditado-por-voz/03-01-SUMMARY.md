# Plan 03-01 — Summary

**Phase:** 3 (Ditado por Voz — Core) | **Plan:** 1 of 3 | **Date:** 2026-09-06
**Status:** ✅ Implementado e testado

## Objetivo
Construir a infraestrutura de dados do ditado por voz: gravação de áudio (web), envio para o Gemini e parse do resultado em um rascunho de lançamento editável (sem tocar em telas ainda).

## Decisões aplicadas (diretrizes da fase, D-31..38)
- **Modelo Gemini `gemini-2.5-flash`** (bloqueado em teste: nunca `2.0`, descontinuado).
- **Transporte REST** com `inline_data` de áudio `audio/webm` (não Live); `x-goog-api-key` via `String.fromEnvironment('GEMINI_API_KEY')`.
- IA devolve **JSON** (`response_mime_type: application/json`) com `valor_reais` como texto pt-BR; categoria/forma restritas às listas fixas da Fase 2; campos não citados → null.
- Correção **campo a campo**: `corrigirCampo` envia rascunho atual + áudio ou texto e devolve só o valor do campo.
- Gravação **push-to-talk**: `record` 6.1.1 com `AudioEncoder.opus`; na web retorna blob URL → bytes via `http.get`.

## Entregue
- Domínio (`features/ditado/domain`): `RascunhoLancamento` (6 campos nullable + `corrigir(campo, valor)` preservando o resto), enum `CampoDitado` (chaves JSON), `LancamentoAudio`, `DitadoException`, interface `DitadoRepository`.
- Dados (`features/ditado/data`):
  - `gemini_prompt.dart`: `modelo = gemini-2.5-flash`; payloads `payloadReconhecer`/`payloadCorrigir` (system instruction pt-BR com listas fixas, temperature 0.1, JSON mode); parsing robusto `textoResposta`/`extraiJson`/`parseRascunho`/`parseCorrecao`.
  - `gemini_ditado_repository.dart`: POST `generateContent`, erros `DitadoException` mapeados (sem chave / HTTP≠200 / resposta vazia).
  - `audio_recorder_service.dart`: abstração `AudioRecorderService` + `RecordAudioRecorderService` (`start(config, path: 'ditado.webm')`, `stop()` → blob URL → bytes).
- Aplicação (`features/ditado/application`): `ditado_providers.dart` com `DitadoState` sealed (Idle/Gravando/Processando/Sucesso/Erro), providers `ditadoRepositoryProvider`, `audioRecorderServiceProvider` e `DitadoController` (`gravar` com permissão, `parar` com reconhecimento, `reiniciar`).
- Testes: `rascunho_lancamento_test`, `gemini_prompt_test` (inclui bloqueio de versão antiga), `gemini_ditado_repository_test` (MockClient), `ditado_controller_test`; fakes `FakeDitadoRepository` e `FakeAudioRecorderService`.

## Verificação
- `flutter analyze`: **No issues found**.
- `flutter test`: **65/65 verdes** (37 novos: 18 prompt + 7 repositório + 7 controller + 9 domínio atendem; suite completa 65).

## Fixes notórios durante a execução
- **Dart não aceita `ç` em identificador** → `erroLançado` → `erroLancado` (mesmo sendo UTF-8 válido).
- Const com `Uint8List.fromList` inválida → `final`.
- Interpolação com `.join()` impede `const` nas instruções → `static final`.
- Corpo de resposta do MockClient com `jsonEncode` aninhado (aspas embutidas quebravam o JSON); asserções ajustadas para o texto real (tonalidade/case) após escape do `jsonEncode`.

## Próximo passo
- **Plan 03-02**: telas S7 (LancamentoDitadoScreen — popup/manter pressionado) e S8 (ConfirmacaoDitadoScreen com itens editáveis campo a campo), FAB "Ditar", rota `/lancamentos/ditar`, conversão rascunho→Lancamento (parse valor BRL), testes de fluxo T1..T5.