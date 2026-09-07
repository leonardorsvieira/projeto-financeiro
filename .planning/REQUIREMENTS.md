# Requirements: Meu Bolso (v1.1)

**Defined:** 2026-09-07 (recriado a partir do archive v1.0)
**Milestone:** v1.1 — Fases 4-8 (Vencimentos/Itens/Recorrências; Lembretes Push; Dashboard e Metas; Recebimentos por Voz; Investimentos)
**Core Value:** O usuário dita um gasto, recebimento ou investimento pela voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar — sem digitação manual.

> Requisitos **v1.0** arquivados em `.planning/milestones/v1.0-REQUIREMENTS.md` (10/31 validados nas Fases 1-3).

## Status do milestone

Fases 4-6 concluídas (2026-09-07). Próximo: **Fase 7 (Recebimentos por Voz)** e, depois, Fase 8 (Investimentos).

## v1.1 Requirements

### Despesas/vencimentos (DSP/RECT — Fase 4)

- [x] **DSP-04**: Usuário adiciona itens/produtos detalhados a uma despesa — *Validated v1.1 (Fase 4): itens editáveis no formulário, soma automática*
- [x] **DSP-05**: Usuário agenda o dia do pagamento/vencimento de uma despesa — *Validated v1.1 (Fase 4): campo vencimento no formulário + badge na lista*
- [x] **RECT-01**: Usuário pode lançar uma despesa manualmente OU marcá-la como fixa mensal (valor recorrente todo mês) — *Validated v1.1 (Fase 4): fixa gera cópias mensais (lazy, no app)*

### Vencimentos/itens por voz (VOZ-04/05 — Fase 4)

- [x] **VOZ-04**: Usuário dita o vencimento/agendamento do dia de pagamento de uma despesa — *Validated v1.1 (Fase 4): extração de "dia 15", vencimento na confirmação*
- [x] **VOZ-05**: Usuário dita os itens/produtos detalhados de uma compra — *Validated v1.1 (Fase 4): itens extraídos pela IA, soma confirmada*

### Lembretes (RECT — Fase 5)

- [x] **RECT-02**: Sistema envia lembrete "X dias antes" do vencimento, com X configurável — *Validated v1.1 (Fase 5): notificação local T-X (padrão 3, configurável 0-30)*
- [x] **RECT-03**: Sistema reapresenta o lembrete no dia do vencimento no horário escolhido pelo usuário — *Validated v1.1 (Fase 5): T-0 no horário configurado*
- [x] **RECT-04**: Usuário visualiza a lista de próximos vencimentos de faturas e contas — *Validated v1.1 (Fase 5): tela dedicada + seção na home (Fase 6)*
- [ ] **RECT-05** *(opcional, post v1.1)*: Push real via FCM/APNs com notificação local como fallback — *adiado; notificação local já cobre o caso*

### Dashboard e metas (DASH — Fase 6)

- [x] **DASH-01**: Usuário vê o saldo do mês (gastos reais + previstos) na primeira tela — *Validated v1.1 (Fase 6): card "Gastos do mês" no Resumo (sem receitas até a F7)*
- [x] **DASH-02**: Usuário vê gráfico de gastos por categoria — *Validated v1.1 (Fase 6): donut fl_chart com legenda*
- [x] **DASH-03**: Usuário vê a lista de próximos vencimentos na primeira tela — *Validated v1.1 (Fase 6): seção no Resumo + "Ver todos"*
- [x] **DASH-04**: Usuário define meta/limite de gasto por categoria e vê o progresso — *Validated v1.1 (Fase 6): tabela `metas`, tela dedicada + progresso no Resumo (ok/alerta/estourada)*

### Recebimentos (VOZ-02 — Fase 7)

- [x] **VOZ-02**: Usuário dita recebimentos (ex.: "recebi 3000 de salário") e a IA registra como receita — *Validated Fase 7: campo `tipo` na migration/modelo/prompt, toggle na confirmação e no form, receitas no saldo do mês (entradas − saídas), lista com badge "Receita"*

### Investimentos (INV + VOZ-03 — Fase 8)

- [ ] **INV-01**: Usuário registra e acompanha ações e FIIs — *Fase 8*
- [ ] **INV-02**: Usuário registra e acompanha cripto — *Fase 8*
- [ ] **INV-03**: Usuário registra e acompanha renda fixa — *Fase 8*
- [ ] **INV-04**: Usuário registra e acompanha investimentos de banco digital (carteiras automáticas) — *Fase 8*
- [ ] **INV-05**: Usuário vê patrimônio total e rendimento acumulado — *Fase 8*
- [ ] **INV-06**: Usuário vê dividendos/rendimentos recebidos por mês — *Fase 8*
- [ ] **INV-07**: Usuário registra compras e vendas de cada ativo — *Fase 8*
- [ ] **VOZ-03**: Usuário dita lançamentos de investimento (ex.: aporte/compra) pela voz — *Fase 8*

## Out of Scope (mantido)

| Feature | Reason |
|---------|--------|
| Integração Open Finance / importação de extratos | Sem dados bancários automáticos; registro é por voz/manual. Adiado para v2 |
| IA assistente conversacional | Restrição "IA gratuita" — ditado inteligente, não conversa |
| Multiusuário/família | Uso individual escolhido na definição |
| IA paga | Restrição de custo: STT e LLM gratuitos (Gemini free tier) |
| Push FCM/APNs (RECT-05) | Notificação local cobre o caso; FCM/APNs opcional post v1.1 |

## Traceability (Fase 7-8)

| Requirement | Phase | Status |
|-------------|-------|--------|
| VOZ-02 | 7 | Validated |
| VOZ-03 | 8 | Pending |
| INV-01..INV-07 | 8 | Pending |

**Coverage até agora:** 14/22 do milestone validados (Fases 4-6 + Fase 7); restam INV-01..07 + VOZ-03 (F8).

---
*Definido: 2026-09-07*