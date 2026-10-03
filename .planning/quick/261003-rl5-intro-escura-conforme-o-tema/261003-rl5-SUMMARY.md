---
phase: quick-261003-rl5
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-rl5 — Intro escura conforme o tema

## Resultado

- **Vídeo escuro** `app/assets/intro/intro_escuro.mp4` (1080×1080, 6 s,
  570 KB): mesmo corte do claro a partir do original, com LUT 3D (mapa afim
  da paleta medida no vídeo — fundo (239,230,213), vermelho (175,49,37),
  marinho (30,43,71) — para papel `#17213A`, tinta `#EF7A70`, letras
  `#F1E8D2`; textura invertida em luminância). Bordas sem halo; fundo
  decodificado `#14203A`.
- **Qual tocar:** tema escolhido no app (Claro/Escuro); em "Sistema"
  (padrão), o do aparelho. Celular: `lerTemaSalvo()` (extraído do
  `ThemeController`) antes do `runApp` + `introEscura()`; `IntroAbertura`
  recebe `escuro` (vídeo, fundo e ícones das barras do sistema). Web:
  `intro.js` lê `localStorage["flutter.app_theme_mode"]` ou
  `prefers-color-scheme`.
- **Fundos:** launch screen Android noturno escuro (`values-night`
  `intro_fundo` = `#14203A`); `body` da web por `prefers-color-scheme` e
  depois pelo tema escolhido. Com tema forçado no app diferente do aparelho,
  o launch screen do Android (antes do Flutter) segue o aparelho por um
  instante.

## Verificação

- `flutter test`: 467 passando (novos: vídeo/fundo escuros, regra
  `introEscura`, `lerTemaSalvo`). `flutter analyze`: só os 9 avisos antigos.
- Web local: aparelho escuro → `intro_escuro.mp4` com fundo `#14203A`;
  aparelho claro → `intro.mp4`; aparelho claro + "Escuro" salvo no app →
  escuro. Sem erros no console.
- **APK 1.2.6 (versionCode 11)**, assinatura de produção, os dois vídeos e
  `intro_fundo` claro/escuro conferidos com aapt/apksigner; copiado para
  `C:\Users\leona\Principal\Desktop\meubolso-release.apk`. Não testado em
  aparelho.
