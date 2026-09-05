# Requirements: Meu Bolso

**Defined:** 2026-09-05
**Core Value:** O usuário dicta um gasto, recebimento ou investimento pela voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar — sem digitação manual.

## v1 Requirements

### Plataforma e Acesso (PLAT)

- [ ] **PLAT-01**: Usuário único faz login com e-mail e senha e permanece logado entre sessões no celular e na web
- [ ] **PLAT-02**: App roda no Android e no iPhone a partir do mesmo código
- [ ] **PLAT-03**: Usuário acessa os mesmos dados pelo navegador no PC
- [ ] **PLAT-04**: Lançamentos feitos em qualquer dispositivo ficam sincronizados (dados na nuvem)
- [ ] **PLAT-05**: Dados financeiros trafegam por HTTPS e são armazenados com segurança (auth), sem vazar para o repositório público

### Captura por voz (VOZ)

- [ ] **VOZ-01**: Usuário dita um gasto e a IA transcreve, extrai valor, categoria e forma de pagamento, e o lançamento só é salvo após confirmação com um toque
- [ ] **VOZ-02**: Usuário dita recebimentos (ex.: "recebi 3000 de salário") e a IA registra como receita
- [ ] **VOZ-03**: Usuário dita lançamentos de investimento (ex.: aporte/compra) pela voz
- [ ] **VOZ-04**: Usuário dita o vencimento/agendamento do dia de pagamento de uma despesa
- [ ] **VOZ-05**: Usuário dita os itens/produtos detalhados de uma compra
- [ ] **VOZ-06**: Em caso de dúvida na captura, o app pede confirmação das informações extras (vencimento, itens) em vez de gravar errado

### Despesas (DSP)

- [ ] **DSP-01**: Usuário lança despesa manualmente com valor, categoria, forma de pagamento, data e notas
- [ ] **DSP-02**: Usuário edita e exclui lançamentos existentes
- [ ] **DSP-03**: Formas de pagamento disponíveis: cartão de crédito, débito, Pix, dinheiro e outros
- [ ] **DSP-04**: Usuário adiciona itens/produtos detalhados a uma despesa
- [ ] **DSP-05**: Usuário agenda o dia do pagamento/vencimento de uma despesa

### Recorrências e lembretes (RECT)

- [ ] **RECT-01**: Usuário pode lançar uma despesa manualmente OU marcá-la como fixa mensal (valor recorrente todo mês)
- [ ] **RECT-02**: Sistema envia lembrete push "X dias antes" do vencimento, com X configurável
- [ ] **RECT-03**: Sistema reapresenta o lembrete no dia do vencimento no horário escolhido pelo usuário
- [ ] **RECT-04**: Usuário visualiza a lista de próximos vencimentos de faturas e contas

### Dashboard (DASH)

- [ ] **DASH-01**: Usuário vê o saldo do mês (entradas − saídas, considerando previstos) na primeira tela
- [ ] **DASH-02**: Usuário vê gráfico de gastos por categoria
- [ ] **DASH-03**: Usuário vê a lista de próximos vencimentos na primeira tela
- [ ] **DASH-04**: Usuário define meta/limite de gasto por categoria e vê o progresso

### Investimentos (INV)

- [ ] **INV-01**: Usuário registra e acompanha ações e FIIs
- [ ] **INV-02**: Usuário registra e acompanha cripto
- [ ] **INV-03**: Usuário registra e acompanha renda fixa
- [ ] **INV-04**: Usuário registra e acompanha investimentos de banco digital (carteiras automáticas)
- [ ] **INV-05**: Usuário vê patrimônio total e rendimento acumulado
- [ ] **INV-06**: Usuário vê dividendos/rendimentos recebidos por mês
- [ ] **INV-07**: Usuário registra compras e vendas de cada ativo

## v2 Requirements

### Integrações

- **INTG-01**: Importação automática de extratos/transações de bancos
- **INTG-02**: Open Finance para leitura de faturas de cartão
- **INTG-03**: Assistente conversacional por voz (IA que responde e pergunta)

### Compartilhamento

- **COMP-01**: Múltiplos usuários/família com contas em comum

## Out of Scope

| Feature | Reason |
|---------|--------|
| Integração Open Finance / importação de extratos no v1 | Sem dados bancários automáticos; registro é por voz/manual. Adiado para v2 |
| IA assistente conversacional | Restrição "IA gratuita" — v1 é ditado inteligente (transcrever + extrair), não conversa |
| Multiusuário/família | Uso individual escolhido na definição |
| IA paga | Restrição de custo: STT e LLM gratuitos (Groq / Gemini free tier) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAT-01 | TBD | Pending |
| PLAT-02 | TBD | Pending |
| PLAT-03 | TBD | Pending |
| PLAT-04 | TBD | Pending |
| PLAT-05 | TBD | Pending |
| VOZ-01 | TBD | Pending |
| VOZ-02 | TBD | Pending |
| VOZ-03 | TBD | Pending |
| VOZ-04 | TBD | Pending |
| VOZ-05 | TBD | Pending |
| VOZ-06 | TBD | Pending |
| DSP-01 | TBD | Pending |
| DSP-02 | TBD | Pending |
| DSP-03 | TBD | Pending |
| DSP-04 | TBD | Pending |
| DSP-05 | TBD | Pending |
| RECT-01 | TBD | Pending |
| RECT-02 | TBD | Pending |
| RECT-03 | TBD | Pending |
| RECT-04 | TBD | Pending |
| DASH-01 | TBD | Pending |
| DASH-02 | TBD | Pending |
| DASH-03 | TBD | Pending |
| DASH-04 | TBD | Pending |
| INV-01 | TBD | Pending |
| INV-02 | TBD | Pending |
| INV-03 | TBD | Pending |
| INV-04 | TBD | Pending |
| INV-05 | TBD | Pending |
| INV-06 | TBD | Pending |
| INV-07 | TBD | Pending |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 31

---
*Requirements defined: 2026-09-05*
*Last updated: 2026-09-05 after initial definition*