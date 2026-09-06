# Plan 01-01 — Summary

**Phase:** 1 (Fundação e Acesso) | **Plan:** 1 of 3 | **Date:** 2026-09-05
**Status:** ✅ Implementado e verificado (gap histórico preenchido na arquivagem do milestone v1.0 em 2026-09-06)

## Objetivo
Walking Skeleton: ambiente Flutter no Windows + projeto "Meu Bolso" em `app/` com tema financeiro PT-BR, home placeholder e smoke test — provando Android/iOS/Web a partir de um único código.

## Entregue
- **Flutter stable** instalado em `C:\src\flutter` e adicionado ao PATH do usuário; `flutter doctor` sem blockers para o alvo web (Android toolchain pendente — anotado como user_setup).
- **Scaffold `app/`** (`flutter create --platforms android,ios,web`): `pubspec.yaml` com `flutter_riverpod`, `go_router`, `supabase_flutter`; `lib/main.dart` com `ProviderScope` + `MeuBolsoApp` (Material 3, pt-BR) e inicialização tolerante do Supabase via `--dart-define`; `lib/theme/app_theme.dart` (seed `0xFF0B7A4B`, light/dark); `lib/features/home/` com home placeholder (S4) e constantes de rota; `test/widget_smoke_test.dart` verde.
- **Build web** validado (`flutter build web --release`) e `.gitignore` protegendo `.env*` e `build/`.
- **`01-SKELETON.md`** com decisões arquiteturais executadas (Flutter 3.47, feature-first, Riverpod, go_router, Supabase sa-east-1, deploy GH Pages baseHref /projeto-financeiro/).

## Verificação
- `flutter analyze`: 0 issues.
- `flutter test`: smoke test verde.
- `flutter build web --release`: ok (`app/build/web/index.html` gerado).
- `.env` e `.dart_tool` ignorados pelo git (verified em execução via check-ignore + commit do lock file).

## Próximo passo
- **Plan 01-02**: backend Supabase (projeto remoto, auth, variáveis de ambiente/segredos fora do git).