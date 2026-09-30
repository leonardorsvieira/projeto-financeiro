---
status: complete
quick_id: 260930-q6z
date: 2026-09-30
---

# Quick 260930-q6z: Caderneta suave (cantos arredondados)

Pedido do usuário: bordas arredondadas também nos ícones e visual menos "seco". Feito inline pelo orquestrador.

- Tokens (`caderneta.dart`): borda 1.5 → 1.0; raioCard 4 → 16; novo raioGrande 24; raioBotao 3 → 14; raioChip → pílula. Novas cores `contorno` (tinta translúcida) e `sombra`; `Caderneta.sombraPapel`.
- Tema (`app_theme.dart`): cards/diálogos/menus com borda translúcida e elevação suave; FAB e chips `StadiumBorder`; aba selecionada em pílula (indicatorPadding no `TabBar` da home); barras de progresso arredondadas; app bar sem linha inferior; checkbox com canto 5.
- `PapelPautado`: contorno translúcido + sombra.
- Widget Android: logo passou a ser o PNG redondo (`ic_launcher_round`).

Também nesta sessão (commits próprios): `fix(android)` pasta de build no release, R8 desligado no release (app fechava ao abrir), `fix(widget)` layout sem `<View>` (RemoteViews).

Verificação: `flutter analyze` (9 infos pré-existentes), `flutter test` 239 passando, web conferida no tema escuro. Aparelho: pendente de retorno do usuário.
