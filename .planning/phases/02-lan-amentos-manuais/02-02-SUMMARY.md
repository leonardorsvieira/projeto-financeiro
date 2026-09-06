# Plan 02-02 — Summary

**Phase:** 02-lan-amentos-manuais | **Plan:** 02 | **Status:** Complete | **Date:** 2026-09-06

## What was done

1. **Dependência `intl`** adicionada ao `pubspec.yaml` (v0.20.2) e `flutter pub get`.
2. **Camada de dados Dart da feature `lancamentos`**:
   - `domain/lancamento.dart` — modelo imutável (id, descricao, `valorCents` int, categoria, formaPagamento, data, vencimento?, obs?, createdAt/updatedAt) com `toMap()` (date-only ISO para data/vencimento) e `fromMap()`.
   - `domain/lancamento_converter.dart` — `parseValorBRLParaCentavos` (vírgula OU ponto como decimal, milhar com ponto, rejeita 3+ casas, zero/negativo/inválido), `formatoBRL` (NumberFormat pt_BR com símbolo `R$`, normaliza NBSP p/ espaço), `formatoData` dd/MM/yyyy manual (sem dependência de locale data no teste), listas fixas `categorias` e `formasPagamento`.
   - `domain/lancamentos_repository.dart` — interface (watch/stream, create, update, delete, findById).
   - `data/supabase_lancamentos_repository.dart` — implementa com `Supabase.instance.client`: `watch()` via `.stream(primaryKey: ['id']).order('data', desc)` (PostgREST+Realtime, RLS), CRUD com `.eq('id', ...)`; **nunca envia user_id**.
   - `application/lancamentos_providers.dart` — `lancamentosRepositoryProvider` (overridable), `lancamentosStreamProvider` (StreamProvider), `lancamentoByIdProvider` (FutureProvider.family).
3. **Testes**:
   - `test/.../domain/lancamento_test.dart` — parser (12,34→1234; 1.234,56→123456; 3 casas/inválido/zero/negativo→null), formatação BRL, data, roundtrip toMap/fromMap.
   - `test/.../application/lancamentos_providers_test.dart` — seeds emitidos, criação/delete refletem no stream, byId.
   - `test/support/fake_lancamentos_repository.dart` — in-memory, broadcast controller, contadores (create/update/delete).

## Decisions taken during execution (recommended options)

- **Representação monetária**: centavos inteiros em todo o stack; conversão estrita na entrada; formatação somente na apresentação (T-04-04).
- **Testabilidade**: interface `LancamentosRepository` permite fake nos testes widget, sem rede.
- **`maybeWhen` é extension method** no Riverpod 3 → em listener dinâmico usar `.value` com cast a `AsyncValue`.

## Verification
- `flutter analyze`: 0 issues.
- `flutter test`: **26 testes verdes** (anteriores 9 + 17 novos).

## Notes for UI plan 02-03

- `lancamento_form_screen` deve usar `parseValorBRLParaCentavos` para o campo valor e `formatoBRL` para exibir edição; dropdowns vêm de `categorias`/`formasPagamento`.
- Lista consome `lancamentosStreamProvider` com `when`/`value` (cast AsyncValue).