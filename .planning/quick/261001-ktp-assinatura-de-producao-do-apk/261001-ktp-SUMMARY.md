---
status: incomplete
quick_id: 261001-ktp
date: 2026-10-01
commit: 4c3bf84
---

# Quick 261001-ktp: assinatura de produção do APK

Objetivo: APK comercial (venda direta, fora das lojas) assinado com chave própria.

- `app/android/app/build.gradle.kts`: o release usa `android/key.properties` (fora do git) quando existe; sem ele, chave de debug + aviso no `build_apk.ps1`.
- Modelo `app/android/key.properties.example`; `*.jks`/`key.properties` já ignorados.
- Versão 1.1.0+4.

Pendente (usuário): criar o keystore com `keytool` e o `key.properties` (senha é do usuário; não criada pelo agente). Depois: gerar o APK release.
