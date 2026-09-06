# Meu Bolso

## What This Is

Aplicativo financeiro pessoal para **um único usuário** (Leonardo) usado no celular (Android e iPhone) e no navegador do PC, acessível de qualquer lugar. **v1.0 no ar:** registra despesas manualmente (valor, categoria, forma de pagamento, data) sincronizadas via nuvem e — o Core — registra gastos **falando**: o usuário dita o lançamento e a IA transcreve, classifica e preenche, com confirmação antes de salvar e correção por voz campo-a-campo. Próximas versões: vencimentos/agendamento e itens, lembretes push, dashboard com metas, receitas e investimentos por voz.

## Core Value

O usuário pode ditar um gasto, recebimento ou investimento com a voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar — sem digitação manual.

## Requirements

### Validated

- ✓ Usar o Meu Bolso no navegador do PC com dados sincronizados — **v1.0** (GH Pages + Supabase realtime)
- ✓ Login de usuário único com e-mail/senha, sessão persistente e dados privados (RLS) — **v1.0**
- ✓ Registrar despesas por ditado de voz inteligente (valor, categoria, forma de pagamento) com confirmação e correção por voz — **v1.0**
- ✓ Registrar despesas manualmente e editar/excluir lançamentos — **v1.0**
- ✓ IA de captura por voz gratuita (free tier, sem custo mensal) — **v1.0**
- ✓ Multi-plataforma (Flutter): código Android/iPhone/Web; validação web no ar, device pendente de toolchain — **v1.0 (parcial)**

### Active

- [ ] Agendar vencimento/agendamento do dia de pagamento e adicionar itens/produtos detalhados à despesa (Fase 4)
- [ ] Lançar contas fixas mensais e/ou valor fixo recorrente por mês (Fase 4)
- [ ] Lembretes push de faturas/cartões "X dias antes" do vencimento (configurável por conta), reapresentando no dia (Fase 5)
- [ ] Dashboard com: saldo do mês, gastos por categoria, próximos vencimentos e metas/limites com progresso (Fase 6)
- [ ] Registrar recebimentos por voz e manualmente, vistos no saldo do mês (Fase 7)
- [ ] Acompanhar investimentos (ações/FII, cripto, renda fixa, banco digital) com patrimônio, dividendos e compras/vendas (Fase 8)

### Out of Scope

- Multiusuário/família compartilhando contas — o usuário escolheu uso individual
- Cartões de crédito com fatura integrada automática via Open Finance no v1 — sem integrações bancárias nesta fase
- Importação automática de extratos de bancos no v1 — registro é por voz/manual
- IA paga/assistente conversacional — restrição de custo (gratuita)

## Context

- Projeto pessoal motivado pelo desejo de ter tudo da vida financeira num só lugar ("meus gastos, investimentos feitos, contas a pagar, quanto vou receber").
- **Deploy v1.0:** GitHub Pages em https://leonardorsvieira.github.io/projeto-financeiro/ (HTTP 200).
- Tech stack real: Flutter 3.47, Supabase (auth, Postgres, realtime), Gemini `gemini-3.5-flash-lite` (free tier) com retry 3x.
- 28 arquivos Dart de app (~90 KB, ~2.4k linhas) + 16 arquivos de teste (81 testes verdes, `flutter analyze` limpo).
- Usuário tem low fidelity inicial: não tem gasto fixo ainda, mas quer a opção de lançar manual OU definir valor fixo mensal (chega na Fase 4).
- Investimentos espalhados: quer acompanhar ações/FIIs, cripto, renda fixa e carteiras de banco digital (Fase 8).
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
| Nome do produto "Meu Bolso" | Curto, popular e fácil de falar | ✅ Confirmado |
| Repositório público `projeto-financeiro` (MIT) | Código aberto, aprendizado e portfólio | ✅ Confirmado |
| Dados reais nunca versionados | Privacy — repo público | ✅ Confirmado (validado nas Fases 1-3) |
| Multiusuário fora do v1 | Uso individual | ✅ Confirmado |
| Acesso por voz como Core Value | Diferencial e motivação do projeto | ✅ Validado (UAT real com ditado funcionando) |
| Flutter + Supabase + GH Pages | Cross-platform + backend grátis + free tier | ✅ Confirmado (v1.0 no ar) |
| Gemini para captura de voz | STT+LLM num endpoint, JSON estruturado, free tier | ✅ Confirmado (com retry; `gemini-3.5-flash-lite`) |
| estabilização no free tier do Gemini | 3.5-flash/3.1-flash-lite/flash-latest falhavam com áudio; 3.5-flash-lite ~75% por chamada + retry 3x | ⚠️ Revisitar se 503s voltarem a incomodar |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-06 after v1.0 milestone*