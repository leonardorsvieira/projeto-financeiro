---
quick_id: 260930-arb
status: complete
---

# Remover telas de proventos e diagnóstico da Pluggy

1. Remover telas Rendimentos e Calendário de Proventos (sem fonte de dados:
   a Pluggy só expõe BUY/SELL em transações de investimento) e toda a camada
   morta de movimentos/rendimentos manuais (modelos, repositórios,
   providers, preço médio, fakes, testes). Manter o rebalanceamento.
2. Tirar o log de diagnóstico de `/investments` e produtos da função `pluggy`
   (voltar ao conteúdo da v8) e redeployar.
