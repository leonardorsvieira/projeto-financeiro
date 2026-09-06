# Phase 03 — Skeleton (arquitetura pretendida)

**Phase:** 3 — Ditado por Voz | **Date:** 2026-09-06

## Novos arquivos (features/ditado)

```
app/lib/features/ditado/
  domain/
    rascunho_lancamento.dart        # RascunhoLancamento (descricao?, valorTexto?, categoria?, forma?, data?, vencimento?)
    ditado_repository.dart          # interface: reconhecer(Uint8List, mime) → RascunhoLancamento
                                    #          corrigirCampo(campo, audio?/texto) → valor campo
  data/
    gemini_ditado_repository.dart   # REST generateContent gemini-2.5-flash (http, dart-define key)
    gemini_prompt.dart              # system prompt + schema + parsing JSON → RascunhoLancamento
  presentation/
    lancamento_ditado_screen.dart   # S7 (gravação push-to-talk, estados, erro)
    confirmacao_ditado_screen.dart  # S8 (form pré-preenchido + botões 🎤 por campo)
```

## Arquivos modificados (reuso Fase 2)

- `lib/router/app_router.dart` → rota `/lancamentos/ditar`.
- `lib/features/home/domain/app_routes.dart` → `lancamentoDitado = '/lancamentos/ditar'`.
- `lancamentos_list_screen.dart` → FAB expandido com "Ditar".
- `lancamento_form_screen.dart` → suporta "modo rascunho" (pré-preenche por injeção, não por futuro) sem quebrar o manual; ou cria-se `confirmacao_ditado_screen.dart` que reusa os widgets de campo do form. **Decisão no plano**: extrair `WidgetsDeFormulario` (# field builder) para S6/S8 compartilhar visual.

## Dependências novas

- `record` (gravação web; bytes webm) + `flutter_lints` já presente.
- `http` já presente (Fase 1/2? verificar pubspec) — usar se já houver; senão `package:http`.

## Novo teste do fluxo (fakes)

- `test/support/fake_ditado_repository.dart` — retorna rascunho pré-programado; captura chamadas.
- `test/features/ditado/...` — unit (prompt parse, mapper) e widget (S7/S8, fluxo completo).

## Deploy

- Workflow GH Pages: adicionar `GEMINI_API_KEY` secret + `--dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}`.
- Local: `.env` (gitignored) + dotenv no build (mesmo padrão Fase 1/2).

## Ordem de execução (plans)

1. **03-01** — infra: `record` no pubspec, `ditado_repository` + `gemini_ditado_repository` + prompt/parsing + mapper → testes unitários.
2. **03-02** — UI: S7 (gravação) + S8 (confirmação/edição com correção por voz) + router/FAB.
3. **03-03** — fim-a-fim: fluxo completo + deploy com a key + checkpoint manual + completar fase.