# Plan 02-03 — Summary

**Phase:** 2 (Lançamentos Manuais) | **Plan:** 3 of 3 | **Date:** 2026-09-06
**Status:** ✅ Implementado e testado (deploy pendente de validação)

## Objetivo
Tornar a tela inicial a lista real de lançamentos (S5) e entregar o formulário de criação/edição (S6), ligados ao router e ao back-end realtime já existentes.

## Decisões de produto (consultadas com o usuário)
- **Home vira a lista** (placeholder substituído por completo; e-mail sai da home, só menu Sair).
- **Valor** digitado como texto livre, validado ao salvar (sem máscara).
- **Edição** por toque no item; menu ⋮ tem apenas **Excluir** (com confirmação).
- **Deploy** no GH Pages + checkpoint manual ao final.

## Entregue
- `lancamentos_list_screen.dart` (S5): ConsumerWidget com erro/empty/list; refresh indicator; FAB "+"; itens com avatar (1ª letra), descrição, ROE + categoria/forma/vencimento; toque abre edição; ⋮ → Excluir com AlertDialog (Cancelar/Excluir); logout no AppBar.
- `lancamento_form_validators.dart`: `validateDescricao`, `validateValor` (parse BRL, > 0), `validateObs` (≤500).
- `lancamento_form_screen.dart` (S6): modo novo/edição via `lancamentoId`; carrega dados para edição (spinner até `_loaded`); campos descrição, valor, data (default hoje), vencimento opcional, dropdowns categoria/forma de pagamento, observação; botão Salvar com `_isSaving`; salva/atualiza via repositório.
- Router: `/home` → `LancamentosListScreen`; rotas `/lancamentos/novo` e `/lancamentos/:id` (edit); `home_screen.dart` removido.
- `test/support/fake_wrappers.dart`: `wrapWithFakes` (auth + lancamentos) e `wrapWithFake`.
- `lancamentos_flow_test.dart`: cenários T1..T6 (empty state; lista renderiza BRL; criar; validação bloqueia submit; editar; excluir confirmar/cancelar).
- `widget_smoke_test.dart` e `router_redirect_test.dart` atualizados.

## Verificação
- `flutter analyze`: **No issues found**.
- `flutter test`: **32/32 verdes** (saltou de 26 com os 6 fluxos novos).

## Fixes notórios durante a execução
- Tap do item usava rota errada (`lancamentoNovo/${id}`) → substituído por `AppRoutes.lancamentoEditar(id)` (`/lancamentos/:id`).
- Botão Salvar fora do viewport em teste → `tester.ensureVisible` antes do tap.
- `_Lista` era `StatelessWidget` sem `ref` → virou `ConsumerWidget`.
- `_confirmarExclusao`: `if (!context.mounted) return;` após `await showDialog`.

## Próximo passo
- Build web release + deploy GH Pages → checklist manual (UAT S6.1..S6.6) → completar fase.