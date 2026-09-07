# Fase 8 — Investimentos (INV-01..07 + VOZ-03)

**Context gathered:** 2026-09-07 via decisões recomendadas (modo consultivo suspenso).

## Requisitos
- INV-01: ações e FIIs; INV-02: cripto; INV-03: renda fixa; INV-04: banco digital (carteiras automáticas).
- INV-05: patrimônio total e rendimento acumulado; INV-06: dividendos/rendimentos por mês.
- INV-07: compras e vendas por ativo (manual ou por voz); VOZ-03: ditado de aporte/compra.

## Decisões recomendadas (registradas)

### D-01 | Sem integração de cotações/API externa
Preço atual de um ativo é **informado pelo usuário** (ou herda o último preço negociado). Zero custo, single-user, MVP. Patrimônio = Σ por ativo de (`quantidade × preço atual`) para ações/FII/cripto, ou `saldo` da carteira para renda fixa/banco digital.

### D-02 | Três tabelas novas (padrão `metas`: RLS + realtime + uuid)
- `investimentos` (posições/ativos): id, user_id, classe, nome, quantidade (double, 0 se n/a), preco_atual_cents, saldo_cents (renda fixa/banco digital), created_at, updated_at.
- `movimentos_investimento`: id, user_id, investimento_id (FK cascade), tipo ('compra'|'venda'), quantidade (double), preco_unit_cents, data, created_at.
- `rendimentos_investimento`: id, user_id, investimento_id (FK cascade), tipo ('dividendo'|'juros'|'rendimento'|'outro'), valor_cents, data, created_at.

### D-03 | Duas formas de precificação por classe
- `acao`, `fii`, `cripto`: posição = `quantidade × preco_atual_cents`.
- `renda_fixa`, `banco_digital`: posição = `saldo_cents` (editável pelo usuário; "quanto vale hoje").

### D-04 | Ganho/perda (INV-05)
`patrimonio − custo`, onde `custo` = Σ compras(qtd×preço) − Σ vendas(qtd×preço). Custo médio implícito. Para RF/bco, movimento 'compra' = aporte, 'venda' = resgate (preco_unit_cents = valor R$ em centavos, quantidade = 1).

### D-05 | Navegação estilo Metas
Tela dedicada `/investimentos` (ação no AppBar da Home, ícone `pie_chart_outline`, mesma classe da tela de metas). Seção "Patrimônio" no dashboard (08-03) com total/ganho e link.

### D-06 | VOZ-03 estende Gemini
O `RascunhoLancamento` **não** exige mudança; cria-se leitura própria no prompt do ditado: `"tipo": "despesa"|"receita"|"investimento"`. Quando `investimento`, campos `investimento_classe`, `investimento_nome`, `operacao` ('compra'|'venda'|'dividendo'), `quantidade`, `preco_unitario` ou `valor`, `data`. Fluxo de confirmação próprio (`ConfirmacaoInvestimentoScreen`) que cria ativo (se não existir) + movimento (+ rendimento se dividendo/juros). Sinais: "comprei", "compre", "aportei", "investi", "vendi", "recebi dividendos", "rendimento".

### D-07 | INV-06 por mês
Tela 08-04 agrupa rendimentos por mês (soma `valor_cents`, dimensão `data`), com form dedicado + registro por voz quando o ditado detectar rendimento.

### D-08 | Documentação
Migration `20260907170000_create_investimentos.sql`. Cálculos derivados (custo/ganho/patrimônio) em providers de application, não persistidos.

## Fases anteriores (excluídas desta fase)
- Cotação automática / importação (out of scope, v2).
- Rebalanceamento, taxas, INSS/IR automático — manual de observação.

---

*Phase: 08-investimentos*
*Context gathered: 2026-09-07 via decisões recomendadas*