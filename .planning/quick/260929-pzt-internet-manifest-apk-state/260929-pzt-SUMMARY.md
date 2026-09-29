---
quick_id: 260929-pzt
status: complete
date: 2026-09-29
---

# Resumo

- `android.permission.INTERNET` adicionada ao manifest principal (antes só no de debug → APK release sem rede).
- `.env` da raiz não existia mais; recriado (fora do git) só com `SUPABASE_URL` e a anon key pública.
- APK debug regerado: `C:\build\meubolso\app\outputs\flutter-apk\app-debug.apk` (2026-09-29 18:45, ~210 MB), com todo o código até `564f0cd` (hardening, Edge Functions, meu.pluggy.ai, /v2/transactions, categorias neutras). O Flutter imprime "Gradle build failed to produce an .apk" por causa da pasta de build alternativa — o APK existe e o script o encontra.
- `STATE.md` e `ROADMAP.md` atualizados: Fases 7 e 8 marcadas concluídas; pendências = "Rescisão" duplicada, testar meu.pluggy no Android, R8 do release.
