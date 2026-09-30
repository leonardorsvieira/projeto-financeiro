---
status: complete
quick_id: 260930-j4c
---

# Quick 260930-j4c: Glassmorphism no app inteiro

Glassmorphism moderno (vidro fosco, sem brilho) aplicado de forma central: fundo em gradiente verde -> petroleo com manchas radiais, cards/app bar/dialogs/sheets/inputs translucidos com borda de 1px, claro (leitoso) e escuro (fumaca).

## Commits
- 2299313 feat(ui): tokens e widgets de vidro (glassmorphism) — `app/lib/theme/glass.dart`, `app/test/theme/glass_test.dart`
- 8f46fbb feat(ui): tema de vidro global e trava biometrica opaca — `app_theme.dart`, `main.dart`, `biometric_lock_wrapper.dart`
- (terceiro) feat(ui): blur real na barra de navegacao e cards de destaque — home_screen, dashboard_screen, lancamentos_list_screen, open_finance_screen

## Resultado
- `flutter test`: 231 testes, todos passam (inclui 6 novos em test/theme/glass_test.dart).
- `flutter analyze`: 9 infos, nenhum erro/warning; todos de deprecacao pre-existentes (theme_selector_dialog RadioGroup, conectar_banco_dialog `value`, pdf_report_service `Table.fromTextArray`).
- `BackdropFilter` so existe em `app/lib/theme/glass.dart`. Nenhum pacote novo.

## Desvios
- Import de teste usa `package:meubolso/` (nome real do pacote).
- `dart format` reformatou `theme_controller.dart`; revertido (fora de escopo).
- Indentacao de `biometric_lock_wrapper.dart` mudou por causa do `GlassBackground` envolvendo o `SafeArea` (layout/textos intactos).

## Pendente
- Checagem visual no navegador (claro/escuro, dialogs, sheets, lock screen) fica com o orquestrador.
