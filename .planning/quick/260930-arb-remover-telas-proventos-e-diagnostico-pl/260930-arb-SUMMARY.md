---
quick_id: 260930-arb
status: complete
---

# Resumo

- Removidas as telas Rendimentos e Calendário de Proventos, suas rotas e o
  botão no Patrimônio; removida a camada de movimentos/rendimentos manuais
  (sem uso desde 260929-rf2) e o cálculo de preço médio. Rebalanceamento
  mantido.
- Função `pluggy` v10 = mesmo conteúdo (hash) da v8, sem o diagnóstico.
- Tabelas `movimentos_investimento`/`rendimentos_investimento` continuam no
  banco (vazias); não foram apagadas.
- `flutter analyze`: só infos antigos; `flutter test`: 225 ✓.
