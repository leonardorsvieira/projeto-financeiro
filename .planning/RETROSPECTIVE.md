# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-09-06
**Phases:** 3 | **Plans:** 9 | **Sessions:** ~2 dias de trabalho

### What Was Built

- App Flutter "Meu Bolso" no ar no GitHub Pages com login Supabase (auth + RLS + realtime)
- Lançamentos de despesas manuais com edição/exclusão e sync em tempo real entre dispositivos
- **Core: ditado por voz** — gravar, IA preenche (identificada por Gemini, modelo `gemini-3.5-flash-lite`), correção e confirmação com um toque; UAT real aprovado pelo usuário

### What Worked

- Fatia vertical por fase (MVP por fatia) — cada fase entrega algo utilizável e testável
- Testes widget + unitários com fakes limpos; 81 testes verdes ao final; `flutter analyze` limpo
- Deploy contínuo via GH Pages a cada push com `--dart-define` para a chave Gemini
- Fluxo "medir no real antes de escolher modelo": testes reais de chamada por modelo resolveram o problema de 503 sem chute

### What Was Inefficient

- O modelo escolhido no plano (`gemini-2.5-flash`) estava descontinuado para chaves novas → 3 tentativas/troca de modelo na execução da Fase 3
- Trabalho refeito no `DitadoController` (gate de 0,5s) para deps-testáveis; `Focus.of` quebrou e exigiu assert por `EditableText.focusNode`
- Primeira tentativa de resolver 503 foi retry+prompt; a troca para flash-lite (mais leve) foi o que de fato estabilizou — custou um push extra
- `01-01-SUMMARY.md` nunca foi escrito na Fase 1 (gap histórico)

### Patterns Established

- Mensagem de estado/moeda sempre em PT-BR; valores em centavos inteiros no modelo
- Retry defensivo no cliente REST com `esperasRetry` injetável nos testes
- Providers sobreponíveis (`FakeRelogio`, `FakeLancamentosRepository` com `createDelay`) para testar temporização
- Decisão de stack/documentos de fase versionados em `.planning/` com commits atômicos por plano

### Key Lessons

1. Valide o serviço externo (modelo, keys, tier) REAL antes de fechar o plano — APIs free tier mudam rápido
2. Quando o serviço externo está instável (503), prefira o modelo "menor/mais leve" + retry a tentar mais requisições no mesmo modelo
3. Consultar o usuário na escolha importante (modelo, deploy) poupou retrabalho — decisão conjunta
4. Testes com temporização precisam de relógio/fakes injetáveis, não de `Future.delayed` real

### Cost Observations

- Gemini free tier (sem custo); Supabase free tier; GH Pages + Actions gratuitos — custo total: R$ 0
- Sessões: 2 dias (2026-09-05 → 2026-09-06)
- Notável: retry 3x no free tier deu ~98% de sucesso por ditado — suficiente para uso pessoal

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 2 | 3 | Validar serviços externos antes de planejar; testar no real antes de decidir modelo |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 81 | n/a (widget/unit sem métrica) | +28 Dart app, +16 testes |

### Top Lessons (Verified Across Milestones)

1. Serviços free tier mudam e degradam — sempre medir no real e ter fallback (retry/modelo alternativo)
2. Tudo que é temporizado/testado precisa de fakes injetáveis — código preparado desde o início
3. Usuário válida no real antes do fechamento — evita entregar feito-errado