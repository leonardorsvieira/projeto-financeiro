# Phase 03 — Research

**Phase:** 3 — Ditado por Voz (Core) | **Date:** 2026-09-06

## Objetivo da pesquisa
Validar a estratégia "serviço único Gemini" (voz → LLM → JSON do lançamento) para push-to-talk de 1 frase no Flutter web, com custo zero.

## 1. Modelo Gemini (transcrição + preenchimento)

- **`gemini-2.0-flash` foi descontinuado em 01/06/2026** — não usar.
- Modelo recomendado: **`gemini-2.5-flash`** (suporta áudio de entrada, structured output/JSON; free tier via API key do Google AI Studio > aistudio.google.com/apikey). Fallback: `gemini-3.x-flash` se houver indisponibilidade na chave.
- Transporte REST: `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent` com `inline_data` (base64). Audio < 20MB é suportado inline — perfeito para frases de poucos segundos.
- Formato áudio aceito: `audio/webm`, `audio/wav`, `audio/mp3`, `audio/ogg`, `audio/m4a`, etc.
- Tokens: 32 tokens/segundo de áudio (~90 segundos ≈ ~3k tokens) — dentro do free tier.
- Structured output: usar Googleschema (`responseMimeType: application/json`, `responseSchema` genérico) pedindo `{descricao, valor_cents, categoria, forma_pagamento, data, vencimento}` — a IA preenche campos vazios com null quando ausentes.

## 2. Gravação no Flutter web

- Pacote **`record`** (v5+): suporta web via MediaRecorder; devolve `Uint8List` em webm/opus. Stop → stream fechado → bytes prontos para base64.
- Necessário permissão de microfone (`getUserMedia`) — `record` dispara o prompt; tratar negação com mensagem amigável.
- Push-to-talk: `start()` / `stop()` controlado por 1 botão.

## 3. Correção por voz (campo a campo)

- Mesmo endpoint REST; enviar **texto** (draft atual + instrução) sem áudio quando a correção é de um campo já transcrito, OU áudio só daquele campo:
  - Alternativa A (simples): re-usa o `generateContent` com áudio só do campo e prompt tipo "extraia apenas X deste áudio".
  - Alternativa B (barata): trocar por Web Speech API para a correção — **descartada** (usuário escolheu serviço único).
- Decisão do plano: **A** — mais fiel à escolha do usuário; custo por correção ~0, já que frases são curtas.

## 4. Integração com a Fase 2

- Reusar: `parseValorBRLParaCentavos`/`formatoBRL`, listas `categorias`/`formasPagamento`, `LancamentoFormScreen`/validators, `lancamentosRepositoryProvider`.
- A IA deve escolher categoria/forma **da lista fixa** (enviadas no prompt); se não citada → `null` → "Outros"/default no form.
- Valor → centavos via parser do app (defesa contra arredondamento); IA retorna `valor_reais_texto` (string) que o parser converte (mais robusto que pedir centavos).

## 5. Deploy / segredos

- `GEMINI_API_KEY` via `--dart-define` local e `secrets.GEMINI_API_KEY` no workflow GH Pages (user secreta; nunca no repo).
- Expoe a API key no client (padrão do Gemini free tier) — risco limitado (quota free); anotar como decisão consciente.

## 6. Riscos

| Risco | Mitigação |
|-------|-----------|
| Gemini indisponível/limite free | Tratar erro com mensagem clara; campo vazio; nunca travar fluxo manual |
| Transcrição financeira errada (pt-BR) | Prompt especializado; confirmação obrigatória; correção por voz/botão antes do Salvar |
| `record` falha em algum browser | Web Speech fallback de captura? Não no MVP — validar no Chrome (alvo) |
| Formato de áudio rejeitado | Usar `audio/webm` (aceito); validar em teste manual |
| Key vazando | Secret no GH Actions; dart-define; `.env` gitignored |

## Conclusão
Estratégia REST + `gemini-2.5-flash` + `record` (webm) atende o MVP: push-to-talk, 1 frase → JSON do lançamento → confirmação editável (voz campo a campo ou botão) → Salvar via repositório existente.