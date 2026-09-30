---
phase: quick-260930-jxk
plan: 01
status: complete
completed: 2026-09-30
commits: [b87d423, 6674ba3, 01e93f7]
---

# Quick 260930-jxk: Tema Caderneta no app

Substituiu o visual de vidro pela identidade Caderneta (papel, tinta azul-marinho, margem vermelha), com modo noturno, fontes locais (Fraunces, Inter, IBM Plex Mono) e paleta de graficos propria.

## Commits
- b87d423 feat(ui): fontes e tokens da identidade Caderneta (pubspec, fontes, caderneta.dart, caderneta_test.dart)
- 6674ba3 feat(ui): tema Caderneta global e remocao do vidro (app_theme, main com licencas OFL, trava biometrica opaca; glass.dart e glass_test.dart removidos)
- 01e93f7 feat(ui): telas no estilo Caderneta (hero pautado, carimbo MB, mic com anel duplo, paleta e verdes de receita)

## Verificacao
- `flutter analyze`: 9 infos, todos pre-existentes (deprecacoes Radio etc.); zero erros/warnings.
- `flutter test`: 231 testes passando.
- `grep Glass|glass.dart|BackdropFilter` em lib/test: vazio.

## Desvios
- [Rule 1] `filledButtonTheme` com `Size.fromHeight(48)` quebrava layouts em Row (largura infinita); usado `Size(64, 48)`.
- [Rule 1] Teste `lancamentos_flow_test` esperava `Colors.green.shade700`; atualizado para `CadernetaCores.claro.receita`.
- Extras alem do plano: `Caderneta.ocre(context)` helper; verdes/ambar e translucidez restantes em `open_finance_screen` e `dashboard_screen` (linha 525) tambem trocados.
- `dart format lib` acidentalmente reformatou todo o projeto (formatter difere do estilo do repo); revertido com `git checkout` por arquivo, e os arquivos novos/alterados nao foram reformatados alem disso.
- Noturno: superficie elevada `#1c2844` (papelClaro) sobre papel `#17213a`.

## Nao feito / observacao
- Nao validado visualmente em dispositivo/web (fontes variaveis com `fontVariations`); recomenda-se conferir no alvo web.
- Textos, icone do app e widget de tela inicial intocados, como previsto.
