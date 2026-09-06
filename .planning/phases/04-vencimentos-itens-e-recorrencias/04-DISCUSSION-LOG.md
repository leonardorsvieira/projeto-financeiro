# Phase 04: Vencimentos, Itens e Recorrências — Discussion Log

> **Audit trail only.** Não usar como input para planejamento, pesquisa ou agentes de execução.
> Decisões capturadas em 04-CONTEXT.md — este log preserva alternativas consideradas.

**Date:** 2026-09-06
**Phase:** 04 — Vencimentos, Itens e Recorrências
**Areas discussed:** Modelagem de itens, Recorrência mensal, Ditado de itens e vencimento, Escopo e nomenclatura

---

## Modelagem de itens (DSP-04)

| Option | Description | Selected |
|--------|-------------|----------|
| JSONB na mesa | Coluna `itens jsonb` na tabela `lancamentos` — sem join, simples, suficiente para single user | ✓ |
| Tabela separada | Tabela `lancamento_itens` com FK — normalização, mais queries no fluxo | |
| Você decide | Deixa a escolha para Claude | |

**Resumo:** JSONB na própria tabela `lancamentos`.

| Option | Description | Selected |
|--------|-------------|----------|
| Nome + valor individual | Cada item tem `descricao` + `valor_cents` — serve para itemizar mercados, notas | ✓ |
| Só descrição | Itens só texto/descrição, sem valor por item | |
| Você decide | Deixa a regra para Claude | |

**Resumo:** Itens com `{descricao, valor_cents}`.

| Option | Description | Selected |
|--------|-------------|----------|
| Soma automática | `valor_cents` = soma dos itens; sem itens → valor digitado normal | ✓ |
| Total independente | Total sempre digitado à parte; itens só descritivos | |
| Sugerir e confirmar | Soma sugerida; usuário confirma antes de salvar | |
| Você decide | Deixa a regra para Claude | |

**Resumo:** `valor_cents` = soma automática dos itens.

| Option | Description | Selected |
|--------|-------------|----------|
| S6 + detalhe | Itens editáveis no formulário S6 e visíveis no detalhe ao tocar | ✓ |
| Somente leitura | Só visíveis no detalhe; mudar requer excluir e refazer | |
| Você decide | Deixa a UX para Claude | |

**Resumo:** Itens editáveis no S6 e visíveis no detalhe.

---

## Recorrência mensal (RECT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Gerar cópias mensais | Fixa = criar cópias dos próximos meses; cada mês seu lançamento independente | ✓ |
| Só marcar como fixo | Lançamento único marcado; dashboard/lembretes assumem (Fase 5/6) | |
| Você decide | Deixa a estratégia para Claude | |

**Resumo:** Gera cópias independentes dos próximos meses.

| Option | Description | Selected |
|--------|-------------|----------|
| Próximo mês para frente | Ao salvar como fixa, nasce a cópia do próximo mês; conforme passa, novas aparecem | ✓ |
| Criar 12 de uma vez | Cria N cópias antecipadas (ex.: 12 meses) | |
| Você decide | Deixa o comportamento para Claude | |

**Resumo:** Materializa apenas o próximo mês; lazy conforme o tempo.

| Option | Description | Selected |
|--------|-------------|----------|
| Excluir individual com opção série | Excluir 1 remove só aquele; opção "excluir série toda" aparece | ✓ |
| Sempre a série toda | Excluir remove todos os meses ligados | |
| Você decide | Deixa o comportamento para Claude | |

**Resumo:** Excluir individual + opção de excluir a série toda.

| Option | Description | Selected |
|--------|-------------|----------|
| Só mensal | Outros períodos → v2 | ✓ |
| Mensal e anual | Escopo maior (ex.: IPTU) | |
| Você decide | Deixa o período para Claude | |

**Resumo:** Só mensal nesta fase.

---

## Ditado de itens e vencimento (VOZ-04/05)

| Option | Description | Selected |
|--------|-------------|----------|
| Ditar lista natural | "arroz 20, feijão 12" → IA devolve `itens[{descricao, valor}]` | ✓ |
| Formato fixo | "item: X, valor: Y" — mais previsível, menos natural | |
| Você decide | Deixa o formato para Claude | |

**Resumo:** Lista natural no ditado.

| Option | Description | Selected |
|--------|-------------|----------|
| Vale a soma confirmada | `valor_cents` = soma dos itens; total dito usado como pista | ✓ |
| Total dito prevalece | Total ditado tem prioridade | |
| Você decide | Deixa a regra de conflito para Claude | |

**Resumo:** Soma confirmada prevalece; total dito é pista.

| Option | Description | Selected |
|--------|-------------|----------|
| Editar na confirmação | Tela de confirmação permite ajustar itens antes de salvar | ✓ |
| Só exibir | Só exibe; mudar requer refazer ditado | |
| Você decide | Deixa a UX para Claude | |

**Resumo:** Itens editáveis na confirmação do ditado.

| Option | Description | Selected |
|--------|-------------|----------|
| Próxima data do dia | "dia 15" → próximo 15 do futuro | ✓ |
| Só datas completas | Só interpreta datas com mês completo (ex.: "15 de dezembro") | |
| Você decide | Deixa a conversão para Claude | |

**Resumo:** "dia 15" convertido para próxima data com esse dia.

---

## Escopo e nomenclatura

| Option | Description | Selected |
|--------|-------------|----------|
| Só despesas | Itens/recorrência só para despesas; receitas → Fase 7 | ✓ |
| Todos os lançamentos | Itens/recorrência para receitas também | |
| Você decide | Deixa o escopo para Claude | |

**Resumo:** Apenas despesas.

| Option | Description | Selected |
|--------|-------------|----------|
| Checkbox 'Fixa mensal' | Checkbox no S6; ao ativo, mostra dia de vencimento | ✓ |
| Dropdown Nunca/Mensal | Dropdown para deixar espaço a outros períodos depois | |
| Você decide | Deixa o controle para Claude | |

**Resumo:** Checkbox 'Despesa fixa mensal' no S6.

| Option | Description | Selected |
|--------|-------------|----------|
| Selo de vencimento + ícone fixa | Badge `vence dd/mm` + ícone de fixa mensal na lista S5 | ✓ |
| Sem indicadores na lista | Só aparece ao abrir o lançamento | |
| Você decide | Deixa a exibição para Claude | |

**Resumo:** Selo + ícone na lista S5.

| Option | Description | Selected |
|--------|-------------|----------|
| Mesmo dia, ajusta fim do mês | Mesmo dia; se não existir (31/fev) → último dia do mês | ✓ |
| Sempre último dia | Sempre último dia do mês | |
| Você decide | Deixa a regra para Claude | |

**Resumo:** Mesmo dia do mês, ajustando para último dia útil.

---

## Mecanismo de cópias (área extra solicitada pelo usuário)

| Option | Description | Selected |
|--------|-------------|----------|
| Geração no app | Ao salvar fixa cria próxima cópia; ao abrir lista garante vigente existe; sem trigger no banco | ✓ |
| Trigger no banco | Lógica no Postgres; menos código Dart, mais difícil de testar | |
| Você decide | Deixa o mecanismo para Claude | |

**Resumo:** Geração no app; sem trigger.

| Option | Description | Selected |
|--------|-------------|----------|
| Fixo mensal + serie_id | `fixo_mensal bool` + `serie_id uuid` (id da primeira da série) | ✓ |
| Só flag | Só `fixo_mensal bool`; série por combinação (frágil) | |
| Você decide | Deixa a modelagem para Claude | |

**Resumo:** `fixo_mensal bool` + `serie_id uuid` na tabela.

---

## Claude's Discretion

- Formatação de datas na cópia.
- Visual dos checkbox e selos (tokens Material 3 existentes).
- Validação de soma: mensagens de erro inline.

## Deferred Ideas

Nenhuma ideia adiada — discussão ficou dentro do escopo da Fase 4.
