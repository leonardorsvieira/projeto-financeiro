# Meu Bolso

## What This Is

Aplicativo financeiro pessoal para **um único usuário** (Leonardo) usado no celular (Android e iPhone) e no navegador do PC, acessível de qualquer lugar. Registra gastos, recebimentos e investimentos — principalmente **falando**: o usuário dita o lançamento e a IA transcreve, classifica e preenche (valor, categoria, forma de pagamento, vencimento e itens detalhados). Lembra de faturas e contas a vencer, mostra um dashboard com saldo do mês, gastos por categoria e próximos vencimentos, e permite metas de gasto por categoria.

## Core Value

O usuário pode ditar um gasto, recebimento ou investimento com a voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar — sem digitação manual.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Usar o Meu Bolso no celular (Android e iPhone) e no navegador do PC, com os mesmos dados sincronizados de qualquer lugar
- [ ] Acesso de usuário único com login seguro e dados privados
- [ ] Registrar despesas por ditado de voz inteligente: valor, categoria, forma de pagamento, vencimento/agendamento do pagamento e detalhamento dos produtos
- [ ] Registrar recebimentos (ex.: salário) por voz e manualmente
- [ ] Registrar lançamentos de investimento por voz e manualmente
- [ ] IA de captura por voz gratuita (sem custo mensal ao usuário)
- [ ] Revisar e editar lançamentos com um toque após o ditado (confirmação)
- [ ] Lembretes push de faturas/cartões "X dias antes" do vencimento (configurável por conta), reapresentando no dia
- [ ] Lançamento manual de contas fixas mensais e/ou valor fixo recorrente por mês
- [ ] Acompanhar investimentos: ações e FIIs, cripto, renda fixa e investimentos de banco digital
- [ ] Visualizar patrimônio, rendimento acumulado, dividendos mensais e compras/vendas de cada ativo
- [ ] Dashboard com: gastos por categoria, próximos vencimentos e saldo do mês
- [ ] Metas/limites de gasto por categoria com barras de progresso

### Out of Scope

- Multiusuário/família compartilhando contas — o usuário escolheu uso individual
- Cartões de crédito com fatura integrada automática via Open Finance no v1 — sem integrações bancárias nesta fase
- Importação automática de extratos de bancos no v1 — registro é por voz/manual
- IA paga/assistente conversacional — restrição de custo (gratuita)

## Context

- Projeto pessoal motivado pelo desejo de ter tudo da vida financeira num só lugar ("meus gastos, investimentos feitos, contas a pagar, quanto vou receber").
- Usuário tem low fidelity inicial: não tem gasto fixo ainda, mas quer a opção de lançar manual OU definir valor fixo mensal.
- Investimentos espalhados: quer acompanhar ações/FIIs, cripto, renda fixa e carteiras de banco digital.
- Idioma: português (PT-BR). Moeda: BRL (Real).
- Repositório público (código aberto, licença MIT) — dados financeiros reais nunca versionados (`.gitignore`); ficam localmente/privados.

## Constraints

- **Mobile multiplataforma**: precisa rodar em Android e iPhone + web — exige stack cross-platform (ex.: Flutter ou React Native) + backend e web
- **IA gratuita**: a captura de voz deve usar serviço/API com tier gratuito viável
- **Departamento de dados**: dados financeiros pessoais são sensíveis — criptografia e privacidade
- **Acesso de qualquer lugar**: exige backend em nuvem com API
- **Custo**: projeto pessoal — hospedagem e serviços o mais baratos possíveis

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Nome do produto "Meu Bolso" | Curto, popular e fácil de falar | — Pending |
| Repositório público `projeto-financeiro` (MIT) | Código aberto, aprendizado e portfólio | — Pending |
| Dados reais nunca versionados | Privacy — repo público | — Pending |
| Multiusuário fora do v1 | Uso individual | — Pending |
| Acesso por voz como Core Value | Diferencial e motivação do projeto | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-05 after initialization*