# Roadmap: Meu Bolso

## Overview

De uma ideia a um app de finanças pessoais falado: primeiro uma fundação sólida (app multi-plataforma + login), depois a capacidade essencial de registrar gastos — manualmente e por voz —, depois vencimentos, lembretes, dashboard/metas e, por fim, investimentos. Cada fase entrega uma fatia vertical utilizável pelo Leonardo ("MVP por fatia").

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Fundação e Acesso** - App rodando em Android/iOS/Web com login único seguro
- [ ] **Phase 2: Lançamentos Manuais** - Registrar, editar e excluir despesas, sincronizadas entre dispositivos
- [ ] **Phase 3: Ditado por Voz (Core)** - Ditar um gasto e a IA preenche; confirma com um toque
- [ ] **Phase 4: Vencimentos, Itens e Recorrências** - Agendar pagamento, detalhar produtos, contas fixas mensais
- [ ] **Phase 5: Lembretes Push** - Avisos "X dias antes" e no dia, na hora escolhida
- [ ] **Phase 6: Dashboard e Metas** - Saldo do mês, gráfico por categoria, vencimentos e metas
- [ ] **Phase 7: Recebimentos por Voz** - Ditar receitas e ver no saldo do mês
- [ ] **Phase 8: Investimentos** - Acompanhar patrimônio, dividendos, compras/vendas e ditar aportes

## Phase Details

### Phase 1: Fundação e Acesso

**Goal:** Aplicativo "Meu Bolso" inicializado em Flutter para Android, iPhone e Web, com login de usuário único.
**Mode:** mvp
**Depends on:** Nothing (first phase)
**Requirements**: PLAT-01, PLAT-02, PLAT-03, PLAT-05
**Success Criteria** (what must be TRUE):

  1. Usuário cria conta com e-mail/senha e faz login no app
  2. App abre no Android, no iPhone e no navegador (web) a partir da mesma base
  3. Sessão persiste ao fechar e reabrir o app
  4. Nenhum dado sensível aparece no repositório público (.env/secrets fora do git)

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 01-01: Scaffold do app Flutter (estrutura, tema PT-BR, navegação)
- [x] 01-02: Backend Supabase (projeto, auth, variáveis de ambiente/segredos fora do git)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03: Tela de login/criação de conta + sessão persistente (Android/iOS/Web)

### Phase 2: Lançamentos Manuais

**Goal:** Registrar despesas manualmente, com todos os campos, sinconizados na nuvem.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: DSP-01, DSP-02, DSP-03, PLAT-04
**Success Criteria** (what must be TRUE):

  1. Usuário lança despesa com valor, categoria, forma de pagamento e data
  2. Usuário edita e exclui lançamentos existentes
  3. Lançamento feito no celular aparece no navegador (e vice-versa), via nuvem
  4. Formas de pagamento: crédito, débito, Pix, dinheiro, outros

**Plans**: 3 plans

Plans:
**Wave 1**

- [ ] 02-01: Schema Supabase + RLS + realtime (despesas isoladas por usuário)
- [ ] 02-02: Camada de dados Dart (model centavos/BRL, repository stream+CRUD, providers)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-03: Telas lista/form (S5/S6), edição/exclusão + sync realtime + deploy web

### Phase 3: Ditado por Voz (Core)

**Goal:** Ditar um gasto (PT-BR, "paguei 50 no mercado") e ver o lançamento pré-preenchido para confirmar com um toque.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: VOZ-01, VOZ-06
**Success Criteria** (what must be TRUE):

  1. Usuário grava voz e o app transcreve em português
  2. IA extrai valor, categoria e forma de pagamento e pré-preenche o lançamento
  3. Lançamento só é salvo após confirmação/ajuste do usuário
  4. Captura usa tier gratuito (sem custo mensal)

**Plans**: 3 plans

Plans:

- [ ] 03-01: Captura de voz + transcrição (Groq whisper, PT-BR)
- [ ] 03-02: Extração estruturada (Gemini free tier) valor/categoria/pagamento → JSON
- [ ] 03-03: Tela de confirmação pós-ditado (regra: só salva após confirmar)

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
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Fundação e Acesso | 0/3 | Not started | - |
| 2. Lançamentos Manuais | 0/3 | Not started | - |
| 3. Ditado por Voz (Core) | 0/3 | Not started | - |
| 4. Vencimentos, Itens e Recorrências | 0/3 | Not started | - |
| 5. Lembretes Push | 0/3 | Not started | - |
| 6. Dashboard e Metas | 0/3 | Not started | - |
| 7. Recebimentos por Voz | 0/2 | Not started | - |
| 8. Investimentos | 0/5 | Not started | - |
