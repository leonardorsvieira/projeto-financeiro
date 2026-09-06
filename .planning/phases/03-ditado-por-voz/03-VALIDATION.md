# Phase 03 — Validation / Nyquist Contract

**Phase:** 3 — Ditado por Voz (Core) | **Status:** ✅ Validado | **Date:** 2026-09-06
**UAT source:** DSP-04, DSP-05 (REQUIREMENTS.md — desempenho/UX voz)

## User Acceptance Criteria

- [x] UAT-10: logado, tocar no mic, ditar "almoço quarenta reais" → confirmação abre com descrição "Almoço" e valor R$ 40,00.
- [x] UAT-11: a IA preenche categoria/forma quando citadas; se não citadas, deixa por conta do usuário (valor nunca trava, campo vazio fica focável).
- [x] UAT-12: antes de salvar dá para editar por toque OU corrigir por voz campo a campo ("Corrigir" junto ao campo).
- [x] UAT-13: Salvar cria lançamento real → aparece na lista (realtime), igual da Fase 2. *("deu certo" no real 2026-09-06 + teste fim-a-fim)*
- [x] UAT-14: sem perm/câmera/mic ou erro da IA → mensagem clara, nada quebra, fluxo manual segue normal. *(erro real da IA observado no 503; fluxo manual nunca quebrou)*

## Nyquist Contract — per task

| Task | What | How to Verify | Pass If |
|------|------|---------------|---------|
| 03-01-01 | Gravação push-to-talk (record, webm) + permissão mic | widget test com fake recoder / smoke | Estado gravando/parado; bytes produzidos; negação tratada |
| 03-01-02 | Cliente Gemini REST: áudio→JSON do lançamento (model gemini-2.5-flash) | teste unitário com client mock (HTTP interceptado) | Prompt correto (sistema + categorias fixas), resposta JSON parseada; campo ausente → null |
| 03-01-03 | Mapper rascunho→`Lancamento` (valores via parser BRL, categorias fixas) | unit test | "quarenta reais" → 4000; categoria fora da lista → null; data null → hoje |
| 03-02-01 | Tela Ditado: botão mic grande, transcrição intermediária, estado processando | widget test (fake gemini) | Mic toca/para; mostra "Processando…"; erro visível |
| 03-02-02 | Confirmação pré-preenchida reusando formulário da Fase 2 | widget test | Form mostra descrição/valor/categoria pré-preenchidos; campos editáveis |
| 03-02-03 | Correção campo-a-campo (botão "Corrigir" → re-dita → merge no form) | widget test | Merging mantém outros campos; Salvar persiste |
| 03-03-01 | Fluxo completo fim-a-fim (fala→confirmação→salvar→lista) | widget test com fakes | item criado no fake repo e visível na lista |
| 03-03-02 | Deploy GH Pages com GEMINI_API_KEY | workflow run | GET URL → 200 |
| Checkpoint | UAT manual (verdade) | usuário revisa | ✅ V10..V12 e V14 confirmados no real (2026-09-06); latência ~3-6s no free tier; bug 503 resolvido trocando para `gemini-3.5-flash-lite` |

## Cross-phase threats

| ID | Risk | Mitigation |
|----|------|------------|
| T-05-01 | API key exposta no client é usada por terceiros | Escopo free tier + quota da conta; key só no dart-define/secret; rotação fácil no AI Studio |
| T-05-02 | Injeção via áudio (prompt) | Prompt fixo, JSON restrito, output validado contra schema + lista fixa + parser BRL |
| T-05-03 | Lançamento duplicado por re-tap | Botão Salvar desabilitado durante save (`_isSaving`, padrão Fase 2) |
| T-05-04 | Dados auditados pelo Google (áudio) | Áudio só enviado para transcrição; sem dados de usuário além da frase ditada; usuário único informado |

## Traceability

| Requirement | Plans/Tasks | UAT |
|-------------|-------------|-----|
| DSP-04 (ditar gasto) | 03-01 (captura+IA), 03-02 (tela+confirmação), 03-03 (fim-a-fim) | UAT-10..13 |
| DSP-05 (confirmar/corrigir) | 03-02 (editar voz/botão) | UAT-12 |
| PLAT-04 (nuvem/realtime) | 03-03 (salvar via repo Fase 2) | UAT-13 |

## Observações (execução)

- **Modelo final:** `gemini-3.5-flash-lite` — stability medição real com áudio: `3.5-flash` 2/6, `3.1-flash-lite` 3/6, `flash-latest` 1/6, **`3.5-flash-lite` 9/12 (~75%)**; com retry 3x do app (~98%).
- **Custo:** free tier (sem cartão), dentro dos limites p/ uso de 1 usuário. Aviso: no free tier a Google pode usar inputs para melhorar o modelo (dados são só a frase ditada — ver T-05-04).
- **Cadeia de decisões de modelo:** `gemini-2.5-flash` descontinuado p/ chaves novas (404) → `gemini-3.6-flash` em 503 (sobrecarga) → `gemini-3.5-flash` → `gemini-3.5-flash-lite` (o mais estável).