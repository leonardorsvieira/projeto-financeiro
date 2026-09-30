---
sketch: 002
name: icone-e-widget-caderneta
question: "Como ficam o ícone do app e o widget da tela inicial na identidade Caderneta?"
winner: "A (ícone Carimbo)"
tags: [identidade, caderneta, icone, launcher, widget, home-widget]
---

# Sketch 002: Ícone e widget · Caderneta

## Design Question
Com a identidade Caderneta escolhida (sketch 001), como devem ficar o ícone do app (hoje o padrão do Flutter) e o widget da tela inicial (hoje uma caixa escura genérica com saldo verde)?

## How to View
http://localhost:8081/002-icone-e-widget-caderneta/index.html (servidor `sketches` do `.claude/launch.json`)

## Variants
Ícone:
- **A: Carimbo** — selo "MB" vermelho/azul-marinho sobre papel creme, levemente inclinado.
- **B: Capa da caderneta** — caderneta fechada azul-marinho com elástico vermelho e etiqueta "MB".
- **C: Página pautada** — pauta azul, margem vermelha e um "B" itálico escrito à mão.

Widget (claro/escuro, Android/iPhone):
- **Compacto 2×2** — o widget atual redesenhado (saldo + vencimentos); sem dado novo.
- **Largo 4×2 · com Ditar** — saldo, receitas/despesas e botão que abre direto o ditado (novo: deep link).
- **Agenda 4×2** — próximos 3 vencimentos como linhas do livro-caixa (novo: lista de vencimentos).

## What to Look For
- O ícone é reconhecível pequeno (notificação) e no recorte redondo do Android?
- O ícone se destaca entre outros apps na tela inicial?
- O widget é legível em papel de parede claro e escuro?
- Obs.: iPhone não tem widget hoje (precisaria de extensão WidgetKit em Swift).
