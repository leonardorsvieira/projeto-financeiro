---
status: complete
quick_id: 260930-lw9
date: 2026-09-30
commit: d0933e9
---

# Quick 260930-lw9: ajustes visuais da Caderneta

Feito inline pelo orquestrador após conferir o app no navegador (web build local, claro e escuro).

- `PapelPautado`: borda passou a ser desenhada por cima (`DecorationPosition.foreground`); a pauta não atravessa mais o contorno do cartão de saldo.
- Paleta de categorias: "Outros" virou cinza neutro; categorias fora da lista padrão (ex.: "Compras", vinda do Open Finance) usam `Caderneta.corExtra` (4 cores extras, estáveis por nome) em vez de repetir a cor de "Outros".
- Gráfico por forma de pagamento: título "Despesas por forma de pagamento". As cores das fatias de cartão continuam vindo da cor do próprio cartão (conteúdo).

Verificação: `flutter analyze` (9 infos pré-existentes), `flutter test` 239 passando, web conferida visualmente.
