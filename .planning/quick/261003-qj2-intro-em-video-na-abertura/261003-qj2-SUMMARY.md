---
phase: quick-261003-qj2
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-qj2 — Intro em vídeo na abertura do app

## Resultado

- **Vídeo:** convertido com ffmpeg (instalado via winget, Gyan.FFmpeg 9.0.2)
  de 4K 16:9 / 10 s / 2,7 MB para **1080×1080 / 6 s / 553 KB** (H.264 main,
  AAC 128k, `+faststart`), recortado no logo, sem o 1º quadro (flash do
  carimbo vermelho) e com fade de áudio de 4,8 s a 6 s. Fundo do vídeo:
  `#F1E8D7`. Arquivo único em `app/assets/intro/intro.mp4`.
- **Celular:** `IntroAbertura` (`features/intro/`, pacote `video_player`)
  toca uma vez por abertura, com som que não interrompe outros apps
  (`mixWithOthers`); toque pula; erro ou 10 s abrem o app.
  `_AberturaComIntro` (`main.dart`) só monta a sessão quando a intro acaba,
  com fade de 400 ms (a biometria pede depois). Launch screen Android em
  creme (`intro_fundo`, também `values-v31`/`values-night-v31`).
- **Web:** `web/intro.js` cria a capa com o mesmo vídeo (mudo — o navegador
  bloqueia som automático) enquanto o Flutter carrega; sai quando o vídeo
  acabou (ou toque) **e** veio `flutter-first-frame`; travas de 10 s (vídeo)
  e 60 s (sinal do app). `retorno-email.js` marca
  `window.meuBolsoDesviando` e a intro não toca no retorno do link de
  e-mail. `body` em creme para não piscar branco.

## Verificação

- `flutter test`: 462 passando (4 novos da intro com plataforma de vídeo
  falsa: fim do vídeo, toque uma vez só, falha ao carregar, tempo máximo).
  `flutter analyze`: só os 9 avisos antigos.
- Build web local servido em localhost: intro toca muda, logo centrado
  (retrato e 1280×720 conferidos pelo DOM), capa some no fim e o app aparece;
  toque pula; `/?code=` vai direto para `confirmado.html` sem intro; sem
  erros de console/CSP.
- Celular: não testado em aparelho nesta sessão (APK gerado para o usuário
  instalar).
