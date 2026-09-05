# Research Summary — Meu Bolso

**Date:** 2026-09-05
**Domain:** Personal finance tracker (single user) — mobile (Android/iOS) + web, voice-first entry, free AI

## Stack (RECOMMENDED)

| Area | Choice | Why |
|------|--------|-----|
| App framework | **Flutter** (3.4x+, Impeller) | One codebase → Android, iOS, **and** web with first-class support. 2026 research points to Flutter for fintech/dashboards and heavy custom UI. Web is a first-party target (Flutter for Web, PWA-capable). |
| Backend / data / auth | **Supabase** (free tier) | Postgres hosted, Auth (email/password, cheap for single user), Realtime, Edge Functions, push notifications (FCM/APNs). Proven 2026 pattern for personal finance: Expo/RN+Clients apps pair with Supabase Auth + Postgres + local SQLite cache. |
| Speech-to-text | **Groq whisper-large-v3-turbo** | Only genuine no-card free tier for STT (~8h audio/day). Portuguese supported. Batch transcription of a short voice clip is fast; fits "ditar + confirmar". Groq also hosts fast free LLM (Llama 3.3 70B) as fallback. |
| LLM for parsing the dictation | **Google Gemini 2.5 Flash (AI Studio free tier)** | Best zero-cost model quality in 2026 for extraction/classification (PT-BR). Maps a phrase like "paguei 50 no mercado" → {valor, categoria, forma de pagamento, vencimento, itens}. Guard: outputs as JSON, use structured prompt, validate. |
| Local cache | SQLite on device (optional) | Offline-friendly; keep data on server as source of truth (single user, sync from anywhere). |
| Push reminders | Supabase + Expo push / FCM+APNs | Schedule "X days before" reminders; deliver at user-chosen time. |

## Table Stakes (esperados do produto)

- Lembretes de vencimento; múltiplas formas de pagamento; categorias; editar/apagar lançamentos; saldo por período.
- Confirmação pós-ditado com um toque (nunca gravar direto sem revisão).

## Pitfalls (a evitar)

1. **Gravar lançamento errado sem revisão** — o ditado de IA erra valor/categoria; todo lançamento por voz exige confirmação editável.
2. **Dados sensíveis em repo público** — nunca versionar valores/bancos; secrets no `.env`/secrets do provedor.
3. **Free tiers mudam** — manter provedor de voz/LLM atrás de um adaptador (trocar Groq↔Gemini sem reescrever).
4. **Custo de push no iOS** — APNs exige conta Apple Developer ($99/ano) p/ notificação real em iOS; planejar fallback (notificação local agendada no app, free).
5. **Fuso/datas** — lançamentos em BRL: tratar datas com timezone do usuário (America/Sao_Paulo).

## Notes

- SQLite single-file é suficiente p/ single user; adotar Postgres (Supabase) só porque exige acesso de qualquer lugar/multi-dispositivo.
- Voz de "dictado inteligente" é batch (grava + transcreve), não streaming — mais simples e econômico.

---
*Synthesized inline (research subagents não disponíveis neste runtime); usado para STACK.md/roadmap.*