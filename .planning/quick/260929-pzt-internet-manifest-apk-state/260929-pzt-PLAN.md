---
quick_id: 260929-pzt
slug: internet-manifest-apk-state
date: 2026-09-29
---

# Permissão INTERNET no manifest + APK novo + STATE

1. Adicionar `android.permission.INTERNET` ao `app/android/app/src/main/AndroidManifest.xml` (só existia no manifest de debug; o APK release ficaria sem rede).
2. Gerar APK debug novo com `build_apk.ps1` — o último era de 2026-09-28 14:23, anterior ao hardening e a todo o Open Finance/meu.pluggy.ai.
3. Atualizar `.planning/STATE.md` e `ROADMAP.md` (Fases 7 e 8 concluídas, pendências atuais).
