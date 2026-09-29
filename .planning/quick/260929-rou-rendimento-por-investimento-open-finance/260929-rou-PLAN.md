---
quick_id: 260929-rou
status: complete
---

# Rendimento por investimento (Open Finance)

Pedido: ver quanto foi aplicado e quanto rendeu em cada investimento e no
total, para saber qual rendeu mais e qual perdeu mais.

1. Migration `investimentos.valor_investido_cents` (nullable).
2. Pluggy: `amountOriginal`, ou `amount − amountProfit`; null se não houver.
3. `Investimento.rendimentoCents` / `rentabilidadePercent`;
   `ResumoRendimentos` (aplicado, atual, rendimento, ranking, maior ganho e
   maior perda) substitui o custo por movimentos manuais.
4. Tela: card com aplicado/atual/rendimento, destaques, valor aplicado e
   rendimento em cada ativo, ranking do que mais rendeu ao que mais perdeu;
   detalhe e dashboard usam os mesmos números.
