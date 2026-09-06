# Phase 04 — Context & Decisions

**Phase:** 4 — Vencimentos, Itens e Recorrências | **Status:** Ready for planning | **Date:** 2026-09-06

## Phase Boundary

- Despesas com **itens detalhados** (DSP-04), **agendamento de vencimento** (DSP-05) e **despesa fixa mensal recorrente** (RECT-01).
- Ditado por voz de **itens** (VOZ-05) e **vencimento** (VOZ-04) — invalidando a soma e preparando confirmação.
- **Apenas despesas** (receitas → Fase 7). Recorrência mensal apenas; outros períodos → v2.

## Constraints / Context Carried From Prior Phases

- Flutter 3.47.2, Riverpod 3, go_router, Supabase projeto `meubolso` (sa-east-1, ref `tkfhthotspehsgvmpsjm`), auth sem confirmação.
- Deploy web no GitHub Pages; validação web-first (Android toolchain adiada).
- Padrões: feature-first, `flutter_riverpod` + `AsyncValue`, `.env` fora do git, testes com fakes sem rede.
- Modelo `Lancamento` já tem campo `vencimento` (nullable) — migration e UI existem desde a Fase 2 (D-14, D-19).
- Modelo `RascunhoLancamento` e `GeminiPrompt` extraem `vencimento` do ditado (Fase 3).

## Decisions

| ID | Decisão | Implicação |
|----|---------|------------|
| D-41 | **Armazenamento de itens:** `itens jsonb` na própria tabela `lancamentos` (não tabela separada) | Sem joins; leitura/realtime simples; suficiente para único usuário |
| D-42 | **Formato do item:** `{descricao: string, valor_cents: int}` (nome + valor individual) | Itens financeiros reais com itemização por produto/serviço |
| D-43 | **`valor_cents` = soma dos itens** quando existem; sem itens → valor digitado normal | O campo mantém a convenção centavos (D-16); soma calculada no app e validada antes de salvar |
| D-44 | **Edição/visualização:** itens editáveis no formulário S6 + visíveis ao tocar no lançamento (detalhe) | Integra ao S6 existente; reutiliza padrão list editável |
| D-45 | **Recorrência mensal:** gera cópias independentes dos próximos meses; cada cópia é `Lancamento` separado | Edição de uma cópia não afeta as outras |
| D-46 | **Materialização:** geração **no app** (sem trigger no banco); ao salvar fixa → cria próxima cópia; ao abrir lista → garante cópia vigente existe | Lógica testável com fakes; mantém toda lógica em Dart |
| D-47 | **Excluir série:** excluir um lançamento individual com opção "excluir série toda" | UX clara sem perder flexibilidade |
| D-48 | **Período:** só mensal nesta fase (semanal/quinzenal/anual → v2) | Escopo reduzido; padrão validado antes de estender |
| D-49 | **Série:** coluna `fixo_mensal bool` + `serie_id uuid` na tabela `lancamentos` | `serie_id` agrupa as cópias; definido na primeira da série e herdado pelas cópias |
| D-50 | **Ditado de itens (VOZ-05):** lista natural ("arroz 20, feijão 12") → IA extrai `itens[{descricao, valor_reais}]` | Prompt atualizado com resposta JSON que inclui campo `itens` |
| D-51 | **Conflito total/soma:** `valor_cents` = soma confirmada; total dito usado como pista, resolvido na confirmação | Usuário revisa a soma antes de salvar |
| D-52 | **Confirmação do ditado:** itens editáveis na tela de confirmação antes de salvar | Fluxo consistente com correção por voz (D-35) |
| D-53 | **Vencimento dito "dia 15":** interpreta como próxima data com esse dia no futuro | Prompt vencimento mantido; app converte `15` → próximo 15 |
| D-54 | **Escopo:** apenas despesas; receitas → Fase 7 | Evita misturar domínios nesta fase |
| D-55 | **UX – fixa:** checkbox 'Despesa fixa mensal' no formulário S6 | Quando ativo, desabilita campos incompatíveis (ex.: variável) |
| D-56 | **UX – lista S5:** selo `vence dd/mm` + ícone de fixa mensal | Indicadores leves sem poluição visual |
| D-57 | **Cópias – dia:** mesmo dia do mês; se o mês não tiver o dia (ex.: 31/fev) → último dia do mês | Regra padrão de calendário mensal |

### Claude's Discretion

- Formatação de datas na cópia (manter iso8601).
- Estilo visual do checkbox e dos selos (tokens Material 3 existentes).
- Validação de soma: mensagens de erro inline quando soma ≠ 0.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Conexões com fases anteriores
- `.planning/phases/03-ditado-por-voz/03-CONTEXT.md` — decisões D-31..38 do ditado (fluxo, IA, confirmação, captura)
- `.planning/phases/02-lan-amentos-manuais/02-CONTEXT.md` — D-14..21 (schema `lancamentos`, modelo Dart, UI S5/S6, RLS)

### Código base a modificar
- `app/lib/features/lancamentos/domain/lancamento.dart` — `Lancamento` modelo (adicionar `itens`, `fixoMensal`, `serieId`)
- `app/lib/features/lancamentos/presentation/lancamento_form_screen.dart` — S6 (adicionar checkbox fixa + campo itens)
- `app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart` — S5 (selo vencimento + ícone fixa)
- `app/lib/features/ditado/data/gemini_prompt.dart` — prompt (adicionar `itens` e regras de ditado)
- `app/lib/features/ditado/domain/rascunho_lancamento.dart` — rascunho (adicionar `itens`)
- `app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart` — confirmação (itens editáveis)
- `supabase/migrations/` — nova migration (colunas `itens`, `fixo_mensal`, `serie_id`)
- `app/lib/features/lancamentos/data/lancamentos_repository.dart` — repositório (lógica de cópia/mensal)

## Existing Code Insights

### Reusable Assets
- **`Lancamento` + `LancamentoConverter`**: modelo imutável com `toMap/fromMap`, padrão `copyWith` — estender com novas colunas.
- **`GeminiPrompt`**: payload JSON `application/json`; instruções com substituição `{hoje}` — adaptar com `itens` e regra de soma.
- **`RascunhoLancamento`**: rascunho com `fromJson/toJson` — estender com `itens`.
- **`LancamentoFormScreen` (S6)**: formulário com validadores inline — adicionar campos.
- **`LancamentoDitadoScreen` + `ConfirmacaoDitadoScreen`**: push-to-talk e confirmação — adicionar edição de itens.
- **Pattern Riverpod**: `StreamProvider` + `AsyncValue` + providers documentados em `ditado_providers.dart` — replicar.

### Established Patterns
- **Centavos inteiros** (`valor_cents bigint`): nenhuma mudança; soma mantida em `int`.
- **RLS own-user**: qualquer nova tabela/coluna herda `auth.uid() = user_id` sem alterar políticas existentes.
- **Migrations versionadas**: `supabase/migrations/YYYYMMDD*.sql`; `supabase db push` para remoto.

### Integration Points
- **S6 (form):** checkbox fixa, seção itens com `Wrap` ou `ListView.builder` para adicionar/remover linhas.
- **S5 (lista):** badge `vence dd/mm` no card; ícone `Icons.replay` (ou `Icons.date_range`) quando `fixoMensal == true`.
- **GeminiPrompt:** campo `itens` na resposta JSON; regras de soma e de "próximo dia 15".
- **Save flow:** ao salvar `fixoMensal`, gerar `lancamento_proximo_mes` com `data = próximo mês mesmo dia`, `serie_id` herdado, `vencimento` herdado.
