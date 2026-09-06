# Roadmap: Meu Bolso

## Overview

De uma ideia a um app de finanças pessoais falado: primeiro uma fundação sólida (app multi-plataforma + login), depois a capacidade essencial de registrar gastos — manualmente e por voz —, depois vencimentos, lembretes, dashboard/metas e, por fim, investimentos. Cada fase entrega uma fatia vertical utilizável pelo Leonardo ("MVP por fatia").

## Milestones

- ✅ **v1.0 MVP** — Fases 1-3 (shipped 2026-09-06) → ver `.planning/milestones/v1.0-ROADMAP.md`
- 🚧 **v1.1** — Fases 4-8 (em planejamento, começando pela Fase 4)

## Phases

**Phase Numbering:**

- Integer phases (4, 5, 6): Planned milestone work
- Decimal phases (4.1, 5.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

<details>
<summary>✅ v1.0 MVP (Fases 1-3) — SHIPPED 2026-09-06</summary>

- [x] **Phase 1: Fundação e Acesso** - App rodando em Android/iOS/Web com login único seguro
- [x] **Phase 2: Lançamentos Manuais** - Registrar, editar e excluir despesas, sincronizadas entre dispositivos
- [x] **Phase 3: Ditado por Voz (Core)** - Ditar um gasto e a IA preenche; confirma com um toque

[Dados completos do milestone arquivados em `.planning/milestones/v1.0-ROADMAP.md`]

</details>

### 🚧 v1.1 (Em planejamento)

- [ ] **Phase 4: Vencimentos, Itens e Recorrências** - Agendar pagamento, detalhar produtos, contas fixas mensais
- [ ] **Phase 5: Lembretes Push** - Avisos "X dias antes" e no dia, na hora escolhida
- [ ] **Phase 6: Dashboard e Metas** - Saldo do mês, gráfico por categoria, vencimentos e metas
- [ ] **Phase 7: Recebimentos por Voz** - Ditar receitas e ver no saldo do mês
- [ ] **Phase 8: Investimentos** - Acompanhar patrimônio, dividendos, compras/vendas e ditar aportes

## Phase Details (v1.1)

### Phase 4: Vencimentos, Itens e Recorrências

**Goal:** Despesas com vencimento agendado, itens detalhados e opção de despesa fixa mensal.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: DSP-04, DSP-05, RECT-01, VOZ-04, VOZ-05
**Success Criteria** (what must be TRUE):

  1. Usuário agenda o dia do pagamento/vencimento ao lançar uma despesa
  2. Usuário adiciona itens/produtos detalhados à despesa
  3. Usuário marca despesa como fixa mensal (gerada todo mês) ou lança manualmente
  4. Usuário dita o vencimento e os itens, capturados pela IA na confirmação

**Plans**: 3 plans

Plans:

- [ ] 04-01: Campos de vencimento/agendamento e itens no modelo e UI
- [ ] 04-02: Recorrência mensal (agendador que gera a despesa fixa no mês)
- [ ] 04-03: Ditado de vencimento e itens na extração da IA (VOZ-04/05)

### Phase 5: Lembretes Push

**Goal:** Notificações que lembram faturas e contas "X dias antes" e no dia do vencimento.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: RECT-02, RECT-03, RECT-04
**Success Criteria** (what must be TRUE):

  1. Usuário configura aviso "X dias antes" do vencimento (X configurável)
  2. Notificação dispara X dias antes e novamente no dia, no horário escolhido
  3. Tela de próximos vencimentos lista as contas a vencer
  4. Notificações funcionam mesmo com free tier (fallback local) no iOS

**Plans**: 3 plans

Plans:

- [ ] 05-01: Tela "próximos vencimentos" (lista ordenada)
- [ ] 05-02: Agendamento de push (FCM/APNs + notificação local como fallback)
- [ ] 05-03: Configuração de período (dias antes) e horário

### Phase 6: Dashboard e Metas

**Goal:** Primeira tela com saldo do mês, gastos por categoria, vencimentos e metas de gasto.
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04
**Success Criteria** (what must be TRUE):

  1. Usuário vê o saldo do mês (entradas − saídas, com previstos)
  2. Usuário vê gráfico de gastos por categoria
  3. Usuário vê próximos vencimentos na primeira tela
  4. Usuário define meta por categoria e vê o progresso

**Plans**: 3 plans

Plans:

- [ ] 06-01: Card de saldo do mês (com previstos)
- [ ] 06-02: Gráfico de gastos por categoria
- [ ] 06-03: Metas/limites por categoria com progresso

### Phase 7: Recebimentos por Voz

**Goal:** Ditar receitas ("recebi 3000 de salário") e vê-las refletidas no mês.
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: VOZ-02
**Success Criteria** (what must be TRUE):

  1. Usuário dita um recebimento e a IA registra como receita (após confirmação)
  2. Receitas aparecem no saldo do mês e no fluxo do dashboard

**Plans**: 2 plans

Plans:

- [ ] 07-01: Ditado de receita na captura por voz
- [ ] 07-02: Receitas no saldo/fluxo do mês (agregado)

### Phase 8: Investimentos

**Goal:** Acompanhar ações/FII, cripto, renda fixa e banco digital — patrimônio, dividendos, compras/vendas e ditado de aporte.
**Mode:** mvp
**Depends on**: Phase 7
**Requirements**: INV-01, INV-02, INV-03, INV-04, INV-05, INV-06, INV-07, VOZ-03
**Success Criteria** (what must be TRUE):

  1. Usuário registra ativos nas 4 classes (ações/FII, cripto, renda fixa, banco digital)
  2. Usuário registra compras e vendas de cada ativo (manual ou por voz)
  3. Usuário vê patrimônio total e rendimento acumulado
  4. Usuário vê dividendos/rendimentos recebidos por mês

**Plans**: 5 plans

Plans:

- [ ] 08-01: Modelo e tela de investimentos/ativos (4 classes)
- [ ] 08-02: Compra e venda por ativo
- [ ] 08-03: Patrimônio e rendimento acumulado
- [ ] 08-04: Dividendos/rendimentos mensais
- [ ] 08-05: Captura de aporte/investimento por voz (VOZ-03)

## Progress

**Execution Order:**
Phases execute in numeric order: 4 → 5 → 6 → 7 → 8 (v1.1)

| Phase             | Milestone | Plans Complete | Status      | Completed  |
| ----------------- | --------- | -------------- | ----------- | ---------- |
| 1. Fundação e Acesso | v1.0 | 3/3 | Complete | 2026-09-06 |
| 2. Lançamentos Manuais | v1.0 | 3/3 | Complete | 2026-09-06 |
| 3. Ditado por Voz (Core) | v1.0 | 3/3 | Complete | 2026-09-06 |
| 4. Vencimentos, Itens e Recorrências | v1.1 | 0/3 | Not started | - |
| 5. Lembretes Push | v1.1 | 0/3 | Not started | - |
| 6. Dashboard e Metas | v1.1 | 0/3 | Not started | - |
| 7. Recebimentos por Voz | v1.1 | 0/2 | Not started | - |
| 8. Investimentos | v1.1 | 0/5 | Not started | - |