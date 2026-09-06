# Phase 03 — CONTEXT (discussão com o usuário)

**Phase:** 3 — Ditado por Voz (Core) | **Date:** 2026-09-06

## Decisões confirmadas pelo usuário na discussão

| # | Pergunta | Resposta | Implicação de design |
|---|----------|----------|----------------------|
| D-31 | Fluxo do ditado | **Pode falar por voz e corrigir por voz OU por botão** (híbrido) | Mic captura a frase; confirmação editável aceita correção por voz (campo a campo) e por toque |
| D-32 | Voz → IA | **Serviço único (voz + LLM)** | Um único provedor (Gemini) transcreve e preenche os campos — nada de Web Speech + outro LLM |
| D-33 | Confirmação | **Formulário editável igual ao manual; ajusta e Salvar** (recomendado) | Reusar `LancamentoFormScreen`/campos da Fase 2 no modo "ditado" |
| D-34 | Escopo mínimo | **MVP vertical: gasto simples** | Suportar "descrição + valor" ditados → lançamento real na lista; receitas/itens ficam para fases futuras |
| D-35 | Correção por voz | **Corrigir campo por campo** | Cada campo tem ação "Corrigir (falar)" que redita só aquele campo, preservando o resto |
| D-36 | Valor ausente | **Deixa vazio, usuário preenche** | IA nunca trava nem pergunta de volta; campo fica vazio com foco |
| D-37 | Serviço de voz | **Gemini Live (API key do usuário)** | Key do Google AI Studio (free tier) via dart-define/secret no deploy; sem fallback no MVP |
| D-38 | Captura | **Push-to-talk, 1 frase por vez** | Tocar o mic, falar, tocar de novo para parar → IA processa e monta confirmação |

## Fluxo de usuário (draft)

1. Na lista de lançamentos, tocar no botão de **microfone** (FAB "+" expande → "Ditar").
2. **Push-to-talk**: tocar no mic grande, falar a frase (ex.: *"almoço quarenta e dois reais e noventa com cartão"*), tocar de novo para parar.
3. IA (Gemini) transcreve e retorna um rascunho estruturado: descrição, valor, categoria, forma de pagamento (e data/vencimento quando citados).
4. **Tela de confirmação** (formulário pré-preenchido, mesmo visual da Fase 2).
5. Usuário confirma tocando em **Salvar** — ou corrige:
   - por **botão**: toca no campo e edita o texto;
   - por **voz**: toca em "Corrigir" ao lado do campo e redita só aquele campo.
6. Salvar → lançamento real criado via repositório da Fase 2 → aparece na lista (realtime).

## Restrições/observações técnicas (a validar na pesquisa)

- **IA gratuita**: Google AI Studio free tier (Gemini). Confirmar modelo de áudio: `gemini-2.0-flash` aceita áudio por REST (`inline_data` base64) — mais simples e suficiente para push-to-talk 1 frase; **Live** (websocket bidirecional) é mais complexo. Decidir no plano (recomendação: REST com áudio upload).
- **Gravador no Flutter web**: package `record` (web via MediaRecorder → webm/opus) — validar formato aceito pelo Gemini (webm ok).
- **Chave**: `GEMINI_API_KEY` em dart-define; disponível no client (padrão Gemini free tier). Adicionar secret no GitHub Actions (deploy Fase 3).
- **Vocabulário financeiro pt-BR**: prompt fixo pede JSON com `{descricao, valor_cents, categoria, forma_pagamento, data, vencimento}`; categorias/forma limitadas às mesmas listas da Fase 2 (a IA escolhe da lista, senão "Outros"). Usar `parseValorBRLParaCentavos`/`formatoBRL` da Fase 2.
- **Erros**: mic sem permissão; IA retorna draft inválido → mensagem clara e campo vazio; nunca salvar sem `valor > 0` e descrição (validador reusado).
- **Mobile**: Fase 1/2 rodam em web no GH Pages; ditar por voz no celular é requisito do produto, mas validação Android fica pendente (toolchain) — mesma política da Fase 1.

## Fora do escopo (MVP)
- Receitas (Fase 7), investimentos (Fase 8), itens detalhados e recorrências (Fase 4), vencimentos automáticos — capturados se ditados, mas sem lógica própria ainda.