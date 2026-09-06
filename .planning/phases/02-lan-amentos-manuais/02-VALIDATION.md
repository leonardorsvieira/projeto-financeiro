# Phase 02 — Validation / Nyquist Contract

**Phase:** 2 — Lançamentos Manuais | **Status:** Planning | **Date:** 2026-09-06
**UAT source:** DSP-01, DSP-02, DSP-03, PLAT-04 (REQUIREMENTS.md)

## User Acceptance Criteria

### DSP-01 — Registrar despesa (manual)
- UAT-01: logado, usuário toca "+" e preenche descrição + valor → ao salvar, lançamento aparece na lista sem recarregar.
- UAT-02: campos categoria, forma de pagamento, data (default hoje) e vencimento opcional são gravados; valor é monetário BRL (vírgula decimal).
- UAT-03: sem descrição ou com valor inválido/zero → mensagens de erro indicam o campo, nada é salvo.

### DSP-02 — Editar despesa
- UAT-04: tocar num lançamento abre o formulário preenchido; alterar descrição/valor/categoria e salvar → lista atualizada e fica refletida em outra aba/dispositivo logado (sync realtime ≤ alguns segundos).

### DSP-03 — Excluir despesa
- UAT-05: menu "Excluir" pede confirmação; confirmar → lançamento some da lista (e das outras sessões); cancelar → permanece.

### PLAT-04 — Dados sincronizados e isolados
- UAT-06: após sessão nova (login) em outra aba, a lista vem da nuvem (persistência).
- UAT-07: usuário **deslogado** (ou outra conta) **não** vê lançamentos de outrem — RLS bloqueia (select anon = 0 linhas).
- UAT-08: reload na web não perde nada (dados vêm da nuvem).

## Nyquist Contract — per task

| Task | What | How to Verify | Pass If |
|------|------|---------------|---------|
| 02-01-01 | Create migration `create_lancamentos` (schema, índices, RLS, publicação realtime) | `supabase db push` / Management API query | Query confirma tabela `lancamentos`, `rls_enabled=true`, policies SELECT/INSERT/UPDATE/DELETE presentes, índice `lancamentos_user_data_idx` |
| 02-01-02 | RLS bloqueia anon | SQL/API: `select * from lancamentos` com role anon | Sem linhas (política exige `auth.uid()`); nenhum leak |
| 02-02-01 | Model `Lancamento` + parse/format centavos↔BRL | `flutter test test/features/lancamentos/domain/lancamento_test.dart` | Verdes; `valorCents=123456` → `R$ 1.234,56`; entrada `"12,34"` → `1234` |
| 02-02-02 | Repository + StreamProvider (stream realtime, RLS) e CRUD | `flutter test` fake repo + widget smoke | Verdes; stream emite itens; create/update/delete chamam Supabase |
| 02-03-01 | S5 Lista: renderiza lançamentos, FAB, empty state, excluir c/ confirmação | `flutter test test/features/lancamentos/presentation/lancamentos_list_test.dart` | Verdes (fake repo); empty state; confirmação aparece; cancelar mantém |
| 02-03-02 | S6 Formulário: validação descricao/valor/categoria/forma/data | `flutter test test/features/lancamentos/presentation/lancamento_form_test.dart` | Verdes; erros inline; salvar c/ dados válidos cria lançamento no fake |
| 02-03-03 | Editar fluxo (abrir item → preencher → salvar) | widget test | Verdes; update no fake |
| 02-03-04 | Deploy GH Pages com base-href e dart-defines | workflow run | GET https://leonardorsvieira.github.io/projeto-financeiro/ → 200 |
| Checkpoint | UAT manual (verdade) | usuário revisa | S6.1 criar→aparece; S6.2 2ª aba sync; S6.3 editar sync; S6.4 excluir c/ confirmação; S6.5 deslogado não vê; S6.6 reload mantém |

## Cross-phase threats (ASVS L1 relevante)

| ID | Risk | Mitigation |
|----|------|------------|
| T-04-01 | IDOR/scope: ler/alterar lançamentos de outro usuário | RLS `auth.uid() = user_id` em todas as policies; app nunca envia `user_id`; default `auth.uid()` na tabela |
| T-04-02 | Payload malicioso (descricao/valor) | Check constraints (`valor_cents > 0`, texto length) + validação client + query builder parametrizado |
| T-04-03 | Tabela exposta a anon (dados sensíveis) | RLS enable + políticas só para authenticated; teste anon vazio |
| T-04-04 | Erro de arredondamento monetário | `valor_cents` bigint; parser restringe 2 casas; formatação só na UI |

## Traceability

| Requirement | Plans/Tasks | UAT |
|-------------|-------------|-----|
| DSP-01 | 02-02, 02-03 (S6 form + S5 lista) | UAT-01..03 |
| DSP-02 | 02-03 (edit flow) | UAT-04 |
| DSP-03 | 02-03 (delete + confirm) | UAT-05 |
| PLAT-04 | 02-01 (schema/RLS/realtime), 02-02 (stream/CRUD), 02-03 (deploy) | UAT-06..08 |