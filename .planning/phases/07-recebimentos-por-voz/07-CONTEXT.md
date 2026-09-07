# Phase 7: Recebimentos por Voz — Context

**Gathered:** 2026-09-07
**Status:** Ready for planning
**Source:** Decisões recomendadas (usuário autorizou seguir recomendações + alterações de máquina durante a Fase 7)

## Phase Boundary

Ditar receitas ("recebi 3000 de salário") e vê-las refletidas no mês: o modelo passa a distinguir **despesa × receita**, a IA classifica o tipo na captura por voz, e o dashboard/saldo/fluxo passam a considerar entradas e saídas.

**Requisito:** VOZ-02. (Não inclui Fase 8 investimentos).

## Implementation Decisions

### Modelo de dados: coluna `tipo` na tabela `lancamentos`

- Recomendação: **uma única tabela `lancamentos` com coluna `tipo text not null default 'despesa'`** com check `tipo in ('despesa','receita')`. Não criar tabela `receitas` separada — itens, `fixo_mensal`, `serie_id`, RLS e realtime já existem; duplicar seria custo sem benefício.
- Valor em centavos continua **positivo** no banco; o sinal/estilo é aplicado na UI (receitas em verde, despesas em vermelho).
- Receitas **não usam** `vencimento`, `fixo_mensal`, `itens` (campos continuam nullable → simplesmente nulos; não adicionar constraint).
- Migração nova `20260907160000_add_tipo_lancamento.sql` em `supabase/migrations/`, aplicada com `supabase db push --linked` (PAT já fornecido, usado só como `SUPABASE_ACCESS_TOKEN` temporário).

### Domínio (Dart)

- `enum TipoLancamento { despesa, receita }` com `dbValue` ('despesa'/'receita') e `fromDb(String)`. Novo tipo em `lancamento.dart`.
- `Lancamento.tipo` (default `despesa`) em `copyWith`, `toMap` (`tipo`), `fromMap` (fallback 'despesa' para linhas antigas).
- `LancamentosRepository.create/update` ganham parâmetro `tipo`; `SupabaseLancamentosRepository` grava `tipo`; `gerarProximaCopiaSeFixa` copia `tipo`; `FakeLancamentosRepository` idem.
- `RascunhoLancamento.tipo` (String? com valores 'despesa'/'receita') + `CampoDitado.tipo` + caso no `corrigir()`.

### Captura por voz (Gemini)

- `GeminiPrompt._instrucaoReconhecer`: adicionar `"tipo": "despesa"|"receita"` ao schema JSON e regras de classificação — verbos/sinais de **receita**: "recebi", "ganhei", "salário", "pagamento recebido", "depósito", "transferência recebida", "dinheiro que entrar", "devolução", "cashback", "dividendo"; sinais de **despesa**: "gastei", "paguei", "comprei", "fatura", "conta de". Default/fallback quando ambíguo: `despesa`. Não inventar tipo se não houver sinal.
- `_instrucaoCorrecao`: regra para `tipo` (só 'despesa'/'receita').

### UI — confirmação do ditado

- Toggle **Despesa / Receita** (ex.: `SegmentedButton`) no topo da `ConfirmacaoDitadoScreen`, inicializado de `rascunho.tipo` (fallback 'despesa').
- Botão microfone para **corrigir `tipo` por voz** (Salvo não decretado por usuário → o toggle permite ajuste manual). Cor `error` para despesa e verde para receita quando aplicável.

### UI — formulário manual (novo/edição)

- Mesmo toggle Despesa/Receita no `LancamentoFormScreen`; **`_prefill` restaura `tipo` na edição** (bug a evitar: editar receita virar despesa). Quando `tipo == receita`, esconder campos vencimento/fixa mensal (não se aplicam).

### Dashboard / saldo / fluxo

- `ResumoMes` passa a ter `entradasCents`, `saidasCents` (real), `previstoCents`. Saldo = **entradas − saídas (real)**; previsto segue separado. Card "Gastos do mês" vira **"Saldo do mês"** no `DashboardScreen` mostrando Entradas (verde), Saídas (vermelho), Saldo (entradas − saídas) e Previsto.
- `gastosPorCategoriaMesProvider`: soma **apenas despesas** (`tipo == despesa`) — donut/metas continuam medindo gasto.
- `proximosVencimentosProvider`: filtra **apenas despesas** (vencimento é conceito de conta a pagar).
- Lista de lançamentos: receitas com sinal `+`, cor verde e badge "Receita"; despesas com `-`/vermelho.

## Claude's Discretion

- Estilo exato do toggle (SegmentedButton vs outras), cores, ícones dos badges e layout do card de saldo ficam a critério da implementação (seguir Material 3 já usado no app e o padrão dos plans 06).

## Canonical References

**Downstream agents MUST read these before implementing.**

### Fase 6 (padrões de providers/telas)
- `.planning/phases/06-dashboard-e-metas/06-01-PLAN.md` — padrão de providers derivados + dashboards
- `.planning/phases/06-dashboard-e-metas/06-02-PLAN.md` — donut por categoria
- `.planning/phases/06-dashboard-e-metas/06-03-PLAN.md` — exemplo de migration + push no Supabase remoto

### Código-fonte
- `app/lib/features/lancamentos/domain/lancamento.dart` — modelo atual (sem `tipo`)
- `app/lib/features/lancamentos/data/supabase_lancamentos_repository.dart` — create/update/cópia fixa
- `app/lib/features/lancamentos/domain/lancamentos_repository.dart` — interface
- `app/lib/features/ditado/domain/rascunho_lancamento.dart` — `CampoDitado` + `corrigir()`
- `app/lib/features/ditado/data/gemini_prompt.dart` — prompt de reconhecimento/correção
- `app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart` — tela de confirmação
- `app/lib/features/lancamentos/presentation/lancamento_form_screen.dart` — formulário manual
- `app/lib/features/dashboard/application/dashboard_providers.dart` — `ResumoMes`/`gastosPorCategoriaMesProvider`
- `app/lib/features/dashboard/presentation/dashboard_screen.dart` — card + donut
- `app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart` — lista
- `supabase/migrations/20260906120000_create_lancamentos.sql` — DDL base

### Testes (padrões)
- `app/test/support/fake_lancamentos_repository.dart`
- `app/test/features/dashboard/application/dashboard_providers_test.dart`
- `app/test/features/ditado/data/gemini_prompt_test.dart`
- `app/test/features/ditado/presentation/confirmacao_ditado_screen_test.dart`
- `app/test/features/ditado/domain/rascunho_lancamento_test.dart`

## Deferred Ideas

- **Fase 8 — Investimentos** (INV-01..07, VOZ-03): representação própria de ativos; fora desta fase.
- Categoria própria para receitas (ex.: Salário): mantida a lista fixa atual; receita pode usar `Outros` ou categoria de origem. Adiar.
- Vencimento para receitas: fora do escopo (não se aplica à maioria dos casos).

---
*Phase: 07-recebimentos-por-voz*
*Context gathered: 2026-09-07 via decisões recomendadas*