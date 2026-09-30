---
status: complete
quick: 260930-lc9
---

# Quick 260930-lc9: Icone Carimbo + widget Agenda

- Icone Carimbo gerado por `app/tool/gerar_icones_test.dart` (`GERAR_ICONES=1 flutter test tool/gerar_icones_test.dart`; em skip sem a variavel). Usa `pintarCarimbo` de `lib/theme/caderneta.dart`, o mesmo painter do `CarimboLogo` (logo do app agora redondo, igual ao icone). Teste do logo ajustado.
- Android (legado, round, adaptativo + colors.xml), iOS (todos do Contents.json), web (192/512/maskable/favicon), manifest com cores Caderneta.
- Widget 4x2: `widget_agenda.dart` (+ teste), `HomeWidgetService` com chaves centralizadas (`limpar()` zera saldo, qtd, legada e 9 chaves), layout/Kotlin/values-night.

Commits: feat(marca), feat(widget) dados, feat(widget) layout.

## Verificado
- `flutter analyze`: 9 infos pre-existentes (deprecacoes), nenhuma nova. `flutter test`: 239 passam.
- PNGs 1024 iOS, 48px mdpi e foreground xxhdpi conferidos visualmente: Fraunces real, carimbo girado.
- `flutter build apk --debug` (chaves falsas): Gradle concluiu, APK em `C:\build\meubolso\app\outputs\flutter-apk\app-debug.apk`; ids Kotlin x XML conferidos.
- Nao verificado em dispositivo/emulador (widget renderizado, tema escuro).

## Desvios
- `drawable-v21/launch_background.xml` nao alterado (usa `?android:colorBackground`, respeita o modo escuro); so `drawable/launch_background.xml` ficou creme.
- `web/index.html` nao tem `theme-color`; nao alterado.
