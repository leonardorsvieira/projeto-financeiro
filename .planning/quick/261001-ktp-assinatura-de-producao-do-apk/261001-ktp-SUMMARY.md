---
status: complete
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

## Concluído

- Chave criada pelo usuário com `criar_chave_assinatura.ps1` (a senha nunca passou pelo agente); `key.properties` + `meubolso-producao.jks` em `app/android/`, fora do git.
- APK comercial: `meubolso-release.apk` 1.1.0 (versionCode 4), assinado com `CN=Meu Bolso, OU=CNPJ 68.018.160/0001-00, C=BR`, `apksigner verify` ok.
- Só 64 bits (arm64-v8a + x86_64): o Controle Inteligente de Aplicativos do Windows (estado 1, ligado) bloqueia o `gen_snapshot` do android-arm. O build 64 bits remove também as libs de 32 bits dos plugins.
- `build_apk.ps1` corrigido para não copiar APK antigo quando o build falha.
