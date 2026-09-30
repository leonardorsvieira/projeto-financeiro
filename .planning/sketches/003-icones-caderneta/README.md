---
sketch: 003
name: icones-caderneta
question: "Qual família de ícones combina com a Caderneta suave (cantos arredondados, papel e tinta)?"
winner: "A (Phosphor Duotone, sem selo)"
tags: [identidade, caderneta, icones, iconografia]
---

# Sketch 003: Ícones da Caderneta

## Design Question
O app usa 89 ícones Material "outlined" padrão (finos e genéricos) que destoam da Caderneta suave. Qual família de ícones — e se vale envolver os ícones num "selo" redondo como o carimbo — dá a cara do app?

## How to View
http://localhost:8081/003-icones-caderneta/index.html (servidor `sketches` do `.claude/launch.json`)

## Variants
- **A: Traço duplo (Phosphor Duotone)** — contorno de tinta com preenchimento suave; o mais acolhedor. Exige o pacote `phosphor_flutter` e o widget `PhosphorIcon` para as duas camadas.
- **B: Traço firme (Phosphor Bold)** — um traço grosso e arredondado; mais legível pequeno. Pacote `phosphor_flutter`.
- **C: Arredondado (Material Rounded)** — variantes `_rounded` já embutidas no Flutter; ativo preenchido. Sem dependência nova.
- **Toggle "Ícones em selo"** — combinável com qualquer família: ícone dentro de círculo de papel; vencimentos com anel vermelho.

## What to Look For
- Os ícones conversam com a fonte Fraunces e o carimbo MB?
- Legibilidade nos tamanhos pequenos (lista, abas) e no tema escuro.
- O selo deixa a tela com mais identidade ou pesada demais?

## Implementation Note
Qualquer que seja a escolha, centralizar em `app/lib/theme/icones.dart` (uma classe `Icones` com um nome por papel: `Icones.resumo`, `Icones.livroCaixa`, `Icones.ditar`...) para trocar a família num lugar só; os testes passam a usar `Icones.*`.
