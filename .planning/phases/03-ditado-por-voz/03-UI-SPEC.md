# Phase 03 — UI-SPEC

**Phase:** 3 — Ditado por Voz (Core) | **Date:** 2026-09-06

## S7 — Tela de Ditado (`lancamento_ditado_screen.dart`)

Rota: `/lancamentos/ditar`. Aberta pelo FAB da lista (S5) → expandido com **"Ditar"** (watch-rec).

```
┌─────────────────────────────┐
│ Meu Bolso            ⋮      │  AppBar (back para lista)
│                             │
│        ┌───────────┐        │
│        │   🎤      │        │  Botão grande central (push-to-talk)
│        │  Manter   │        │  Idle: "Manter para falar" (cinza)
│        └───────────┘        │  Gravando: pulse vermelho + "Falando…"
│   Processando… (spinner)    │  Estado IA: "Analisando…"
│                             │
│   [Dica] Fale o gasto, ex.:  │
│   "almoço quarenta reais    │
│    com cartão"              │
└─────────────────────────────┘
```

Comportamento:
- **Push-to-talk**: press-and-hold (GestureDetector onLongPressStart/End) OU tap start/tap stop (escolhido: **tap start + tap stop** — D-38; hold também aceito se natural ao toque). Decisão fixa: botão alterna (start/stop) — mais simples no mobile.
- Enquanto grava: vibrante (estado `gravando`), mostra duração; stop → `processando` (spinner + "Analisando…").
- Sucesso → `Navigator.push` para S8 com o rascunho.
- Erro/fluxo cancelado → SnackBar/estado com "Tentar de novo".

## S8 — Confirmação (formulário pré-preenchido)

Reusa o visual de S6 (Fase 2), com **um botão extra de voz por campo**:

```
┌─────────────────────────────┐
│ Corrigir por voz        🎤  │  chave do rascunho
│                             │
│ Descrição         [Almoço ] │  Trailing: [🎤 Corrigir]
│ Valor (R$)        [40,00  ] │                [🎤]
│ Categoria         [Aliment.]│                [🎤]  (dropdown)
│ Forma             [Cartão ] │                [🎤]
│ Data              [06/09 ]  │                [🎤]  (picker)
│ Vencimento        (opcional)│
│                             │
│        [ Cancelar ] [Salvar ]│  botões fixos no fim / topo
└─────────────────────────────┘
```

- Tocar **🎤 no campo** → grava 1 frase → IA retorna só aquele campo → merge no formulário (D-35: corrigir campo por campo, resto preservado).
- Os botões 🎤 ficam **dentro do campo** só quando há rascunho; no modo manual não aparecem.
- **Valor ausente → campo vazio com foco** (D-36); pode digitar ou corrigir por voz.
- Salvar: mesmo fluxo S6 (`_salvar`) → repositório → pop 2 → lista.

## FAB da lista (mudança em S5)

- FAB `+` atual vira barra expandida: **[ Ditar 🎤 ] [ Manual + ]** — 2 ações. Simples: dois FABs empilhados (FloatingActionButton) via `FloatingActionButton.extended` para "Ditar".

## Estados/erros

| Situação | UI |
|----------|----|
| Mic sem permissão | SnackBar "Permita o microfone para ditar" |
| Gravação muito curta (<0.5s) | Ignora, volta a idle |
| IA falha/timeout | Tela com "Não consegui entender. Tente de novo ou use o manual." |
| Rascunho com valor vazio | Confirmação abre; foco em Valor; Salvar segue regras do validador |
| Salvando | Botão Salvar com spinner (padrão S6) |

## Tokens/copy (pt-BR)

- "Manter para falar" (hold) / "Toque para gravar" (tap-start) — fixo: **tap-start**: label alterna "Toque para gravar" ↔ "Toque para parar".
- Título S7: "Ditar lançamento".
- Dica: *"Fale o gasto. Ex.: 'almoço quarenta reais com cartão'."*