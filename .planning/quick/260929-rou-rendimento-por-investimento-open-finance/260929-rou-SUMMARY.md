---
quick_id: 260929-rou
status: complete
---

# Resumo — Rendimento por investimento

- Migration `20260929225622_investimentos_valor_investido` aplicada no remoto.
- Valor aplicado vem da Pluggy (`amountOriginal`, fallback
  `amount − amountProfit`); ativos sem o dado ficam fora do rendimento e a
  tela avisa.
- Patrimônio: card com total aplicado, valor atual e quanto rendeu/perdeu
  (R$ e %); cartão "Mais rendeu / Mais perdeu"; cada ativo mostra aplicado e
  rendimento; botão de ranking ordena do que mais rendeu ao que mais perdeu.
- Detalhe do ativo e card do dashboard usam o mesmo cálculo (dashboard não
  mostra mais o patrimônio inteiro como "rendimento" quando falta o dado).
- Removidos providers de custo/preço médio por movimentos manuais.
- `flutter analyze`: só infos antigos; `flutter test`: 240 ✓.
