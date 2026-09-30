---
phase: quick-260930-jxk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - app/pubspec.yaml
  - app/assets/fonts/Fraunces.ttf
  - app/assets/fonts/Fraunces-Italic.ttf
  - app/assets/fonts/Inter.ttf
  - app/assets/fonts/IBMPlexMono-Regular.ttf
  - app/assets/fonts/IBMPlexMono-SemiBold.ttf
  - app/assets/fonts/OFL-Fraunces.txt
  - app/assets/fonts/OFL-Inter.txt
  - app/assets/fonts/OFL-IBMPlexMono.txt
  - app/lib/theme/caderneta.dart
  - app/lib/theme/glass.dart
  - app/lib/theme/app_theme.dart
  - app/lib/main.dart
  - app/lib/features/seguranca/presentation/biometric_lock_wrapper.dart
  - app/lib/features/dashboard/presentation/home_screen.dart
  - app/lib/features/dashboard/presentation/dashboard_screen.dart
  - app/lib/features/dashboard/presentation/historico_meses_screen.dart
  - app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart
  - app/lib/features/ditado/presentation/lancamento_ditado_screen.dart
  - app/lib/features/auth/presentation/login_screen.dart
  - app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart
  - app/lib/features/open_finance/presentation/open_finance_screen.dart
  - app/lib/features/relatorios/presentation/relatorios_screen.dart
  - app/lib/features/relatorios/presentation/widgets/comparativo_mensal_chart.dart
  - app/lib/features/investimentos/presentation/investimentos_screen.dart
  - app/lib/features/investimentos/presentation/rebalanceamento_dialog.dart
  - app/lib/features/metas/presentation/metas_screen.dart
  - app/test/theme/caderneta_test.dart
  - app/test/theme/glass_test.dart
autonomous: true
requirements: [QUICK-260930-jxk]

must_haves:
  truths:
    - "O app inteiro (claro e escuro) tem visual de caderneta: fundo papel opaco, tinta azul-marinho, bordas de 1.5px, cantos de 3-4px, sem sombra e sem blur"
    - "Títulos em Fraunces, texto de UI em Inter e valores/datas em IBM Plex Mono, com o peso certo na web e no celular"
    - "O card de saldo do dashboard é papel pautado com margem dupla vermelha à esquerda"
    - "O botão de gravar do ditado é redondo em tinta com anel duplo (papel + tinta)"
    - "O cabeçalho da home e o login mostram o carimbo MB"
    - "O seletor de tema (claro/escuro/sistema) continua funcionando e a tela de bloqueio biométrico é opaca"
    - "Não existe mais BackdropFilter, GlassBackground, GlassSurface nem GlassCard no app"
  artifacts:
    - path: "app/lib/theme/caderneta.dart"
      provides: "Tokens Caderneta (claro/noturna), paleta de categorias, estilos de texto, widgets PapelPautado, MargemVermelha, CarimboLogo"
      contains: "class CadernetaCores"
    - path: "app/lib/theme/app_theme.dart"
      provides: "ThemeData claro/escuro Caderneta com ColorScheme manual e TextTheme com fontes locais"
      contains: "Fraunces"
    - path: "app/pubspec.yaml"
      provides: "Registro das famílias Fraunces, Inter, IBMPlexMono"
      contains: "family: IBMPlexMono"
    - path: "app/test/theme/caderneta_test.dart"
      provides: "Testes dos tokens e widgets Caderneta"
  key_links:
    - from: "app/lib/theme/app_theme.dart"
      to: "app/lib/theme/caderneta.dart"
      via: "CadernetaCores.de(brightness) alimenta ColorScheme e component themes"
      pattern: "CadernetaCores"
    - from: "app/lib/features/dashboard/presentation/dashboard_screen.dart"
      to: "app/lib/theme/caderneta.dart"
      via: "hero de saldo com PapelPautado + paleta de categorias no donut"
      pattern: "PapelPautado|Caderneta\\.paletaCategorias"
    - from: "app/lib/main.dart"
      to: "LicenseRegistry"
      via: "licenças OFL registradas na inicialização"
      pattern: "LicenseRegistry\\.addLicense"
---

<objective>
Substituir o visual de vidro (quick 260930-j4c) pela identidade "Caderneta" (livro-caixa de papel e tinta, variante B vencedora do sketch 001) — só a camada visual: tema, fontes, componentes e cores de gráfico.

Purpose: dar ao Meu Bolso uma identidade própria e legível (papel creme, tinta azul-marinho, margem vermelha), com modo escuro "caderneta noturna".
Output: `app/lib/theme/caderneta.dart` (tokens + widgets), `app_theme.dart` reescrito, fontes registradas, glass removido, telas-chave (home, dashboard, ditado, login) ajustadas.

FORA DE ESCOPO (quick tasks separadas depois): textos/microcopy, ícone do app (launcher/favicon), widget de tela inicial (`home_widget`). NÃO mudar nenhuma string visível, nenhum ícone `Icons.*` existente (testes procuram `Icons.mic_none`), nem o ícone/widget nativo. Cores das faces de cartão em `cartoes_screen` e cores do `pdf_report_service.dart` ficam como estão.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@.planning/STATE.md
@.planning/sketches/001-identidade-visual-e-voz/README.md
@.planning/quick/260930-j4c-glassmorphism-aero-glass-no-app-inteiro/260930-j4c-SUMMARY.md
@app/lib/theme/app_theme.dart
@app/lib/theme/glass.dart

<interfaces>
Tokens da variante Caderneta (sketch 001, `.planning/sketches/001-identidade-visual-e-voz/index.html` linhas 147-159, bloco `.v-caderneta`):
- bg papel #f4ecd8; surface papel claro #fbf6ea; ink/primary #1d2a47; on-primary #f4ecd8; muted #6f6a5c; aviso/accent #b3261e; ok/receita #2d6a3e; chip #ebe1c7; trilho (track de progresso) #e4d9bd; hover #efe5cc
- borda 1.5px solid ink; divisor 1px solid #cdbf9c; pauta #d9ccaa
- raios: card 4, chip 3, botão 3, mic círculo, barra de progresso 0 (altura 8)
- mic: sombra-anel "0 0 0 6px papel, 0 0 0 7.5px ink" (anel papel de 6px + anel tinta de 1.5px)
- hero: fundo pautado (linhas de 1px #d9ccaa a cada 28px sobre #fbf6ea) + border-left 6px double #b3261e
- lista: pauta a cada 60px + border-left 2px #b3261e
- títulos de tela em itálico (Fraunces Italic); display weight 600, letter-spacing -0.01em; números IBM Plex Mono weight 600
Caderneta noturna (escuro): papel #17213a (bg) / #111a2e (surface mais funda) ou #1c2844 (surface elevada — escolher contraste legível), tinta creme #f1e8d2, vermelho #ef7a70, pauta #243154, muted #a9a18c, receita verde claro (ex.: #7fbf8e — discricionário, precisa contraste AA sobre #17213a).
Paleta de categorias (gráficos): #1d2a47 ink, #b3261e vermelho, #2d6a3e verde, #8a6d2f ocre, #5c5c7a ardósia, + variantes apagadas (ex.: #4a5a7a, #c8736b, #6f8f5a, #a08a5a) para chegar a 9. No escuro, usar versões claras equivalentes (ex.: tinta vira creme #f1e8d2, vermelho #ef7a70...).

Pontos de uso do vidro hoje (todos devem sair):
- app/lib/main.dart:15 import glass; :123 `GlassBackground(child: BiometricLockWrapper(...))` dentro de `MaterialApp.router(builder:)`
- app/lib/features/seguranca/presentation/biometric_lock_wrapper.dart:5 import; :98 `body: GlassBackground(`
- app/lib/features/dashboard/presentation/home_screen.dart:13 import; :68 `flexibleSpace: const GlassSurface(blur: true, ...)` + `backgroundColor: Colors.transparent`; título atual = Row(Icon(Icons.account_balance_wallet_outlined), 'Meu Bolso')
- app/lib/features/dashboard/presentation/dashboard_screen.dart:17 import; :131 `_CardGastosMes` usa `GlassCard` (hero "Saldo do mês"); :232 outro `GlassCard`; :21-29 mapa de cores por categoria (Material vivo); verdes `Colors.green.shade700/600` em :143,:155,:226,:438; `Colors.amber.shade700` em :437
- app/lib/theme/app_theme.dart usa `GlassTokens`, `GlassPageTransitionsBuilder`, `scaffoldBackgroundColor: Colors.transparent`, `ColorScheme.fromSeed(0xFF0B7A4B)`
- Translucência residual da j4c: lancamentos_list_screen.dart:146 e open_finance_screen.dart:511 `surfaceContainerHighest.withValues(alpha: 0.5)`
- Mic do ditado: lancamento_ditado_screen.dart widget privado `_BotaoMic(cor:, icone:, ...)` (~linha 125), estados usam `tema.colorScheme.primary`/`error`
- Login: login_screen.dart:62 `Icons.account_balance_wallet_outlined` como logo
- Verdes de receita também em: historico_meses_screen.dart:167,178; relatorios_screen.dart:121,133,143,201,212; comparativo_mensal_chart.dart:60,90,188; lancamentos_list_screen.dart:322,331,367; investimentos_screen.dart:162; relatorio_cartoes_widget.dart:81 (0xFF0B7A4B), :110,:160 (0xFF32BCAD)
- Nome do pacote nos imports de teste: `package:meubolso/...`
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Fontes registradas + tokens e widgets Caderneta (caderneta.dart)</name>
  <files>app/pubspec.yaml, app/assets/fonts/* (commitar), app/lib/theme/caderneta.dart, app/test/theme/caderneta_test.dart</files>
  <behavior>
    - CadernetaCores.de(Brightness.light).papel == Color(0xFFF4ECD8), .tinta == Color(0xFF1D2A47), .margem == Color(0xFFB3261E), .receita == Color(0xFF2D6A3E)
    - CadernetaCores.de(Brightness.dark).papel tem luminância < 0.1 e .tinta luminância > 0.7 (noturna: papel navy, tinta creme)
    - Caderneta.paletaCategorias(Brightness.light) tem >= 9 cores distintas e começa com 0xFF1D2A47, 0xFFB3261E, 0xFF2D6A3E, 0xFF8A6D2F, 0xFF5C5C7A
    - CadernetaTexto.numero(...) retorna TextStyle com fontFamily 'IBMPlexMono'; CadernetaTexto.display(...) com fontFamily 'Fraunces' e fontVariations contendo FontVariation.weight(600)
    - PapelPautado renderiza o filho e tem uma borda esquerda (MargemVermelha) — widget test acha o texto filho e um CustomPaint
    - CarimboLogo renderiza o texto 'MB' e não usa BoxShadow
  </behavior>
  <action>
    (a) Fontes: os arquivos já estão em app/assets/fonts/ (não commitados). Em app/pubspec.yaml, sob `flutter:` (depois de `uses-material-design: true`), adicionar seção `fonts:` com três famílias: `Fraunces` (asset assets/fonts/Fraunces.ttf; e assets/fonts/Fraunces-Italic.ttf com `style: italic`), `Inter` (assets/fonts/Inter.ttf), `IBMPlexMono` (assets/fonts/IBMPlexMono-Regular.ttf weight 400; assets/fonts/IBMPlexMono-SemiBold.ttf weight 600). Adicionar também `assets:` com os três `assets/fonts/OFL-*.txt` para poderem ser lidos por rootBundle (licenças). Não adicionar pacote novo (nada de google_fonts). Rodar `flutter pub get`.

    (b) Criar app/lib/theme/caderneta.dart (substitui glass.dart; sem BackdropFilter, sem BoxShadow) contendo:
    - `class CadernetaCores` imutável com campos: papel (bg), papelClaro (surface), papelChip, trilho, hover, tinta, tintaSobrePrimaria (on-primary), apagado (muted), margem (vermelho), receita, pauta, divisor; `static CadernetaCores de(Brightness b)` e `static CadernetaCores of(BuildContext c)`. Valores claros exatamente os de <interfaces>; noturna: papel #17213a, papelClaro #1c2844 (ou #111a2e — escolher o que der contraste e documentar), tinta #f1e8d2, tintaSobrePrimaria #17213a, margem #ef7a70, pauta/divisor #243154, apagado #a9a18c, receita verde legível (discrição, ex. #7fbf8e).
    - `class Caderneta` com constantes: `borda = 1.5`, `raioCard = 4.0`, `raioChip = 3.0`, `raioBotao = 3.0`, `alturaBarra = 8.0`, `espacoPauta = 28.0`; `static List<Color> paletaCategorias(Brightness b)` (ordem de <interfaces>, 9+ cores; escuro com variantes claras); `static Color corReceita(BuildContext c)` e `static Color corReceitaFundo(BuildContext c)` (receita com alpha ~0.12) para substituir os `Colors.green.*` no Task 3.
    - `class CadernetaTexto` com helpers estáticos `display({double size, Color? cor, bool italico=false})` (family 'Fraunces', fontWeight w600 + `fontVariations: [FontVariation.weight(600)]`, letterSpacing -0.01*size), `corpo(...)` (family 'Inter', peso configurável com fontWeight + FontVariation.weight coerentes), `numero({double size, Color? cor, FontWeight peso = w600})` (family 'IBMPlexMono', mapeia para os arquivos estáticos; incluir `fontFeatures: [FontFeature.tabularFigures()]`). Motivo das fontVariations: fontes variáveis no Flutter não instanciam o eixo wght só com fontWeight (CanvasKit na web renderiza sempre o default).
    - Widgets: `PapelPautado({child, padding, espacamento = Caderneta.espacoPauta, margem = true})` — fundo papelClaro, CustomPainter desenhando linhas horizontais de 1px na cor pauta a cada `espacamento`, borda de 1.5px tinta com raio 4, e (se margem) `MargemVermelha` à esquerda; `MargemVermelha` — duas linhas verticais vermelhas finas (1.5px, gap 3px = "6px double") desenhadas por CustomPainter ou Row de Containers; `CarimboLogo({double tamanho = 36})` — selo "MB": Container quadrado com cantos 4, borda dupla (borda externa 1.5px margem vermelha + interna 1.5px tinta via Container aninhado com padding 2) e Text 'MB' em CadernetaTexto.display itálico na cor tinta, levemente rotacionado (Transform.rotate ~ -0.05 rad). Nada de sombras.
    - `class CadernetaPageTransitionsBuilder extends PageTransitionsBuilder` (mesma ideia do GlassPageTransitionsBuilder: envolve o child num `ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)` opaco para a rota de baixo nunca aparecer).

    (c) Criar app/test/theme/caderneta_test.dart cobrindo o <behavior> (imports `package:meubolso/theme/caderneta.dart`). Escrever os testes primeiro (RED), depois implementar (GREEN).
  </action>
  <verify>
    <automated>cd app && flutter pub get && flutter test test/theme/caderneta_test.dart</automated>
  </verify>
  <done>pubspec registra Fraunces/Inter/IBMPlexMono e as licenças; caderneta.dart existe com CadernetaCores, Caderneta, CadernetaTexto, PapelPautado, MargemVermelha, CarimboLogo, CadernetaPageTransitionsBuilder; caderneta_test.dart passa; `grep -c "BoxShadow\|BackdropFilter" app/lib/theme/caderneta.dart` == 0.</done>
</task>

<task type="auto">
  <name>Task 2: AppTheme Caderneta (claro + noturno), remover vidro global, licenças OFL, trava opaca</name>
  <files>app/lib/theme/app_theme.dart, app/lib/theme/glass.dart (apagar), app/test/theme/glass_test.dart (apagar), app/lib/main.dart, app/lib/features/seguranca/presentation/biometric_lock_wrapper.dart</files>
  <action>
    Reescrever app/lib/theme/app_theme.dart mantendo a API pública (`AppTheme.light`, `AppTheme.dark`, e as constantes `backgroundLight`/`backgroundDark` — atualizar para papel #f4ecd8 / #17213a; manter `seed` só se algo externo usar, conferir com grep). Em `_base(Brightness)`:
    - `ColorScheme` construído à mão a partir de `CadernetaCores.de(b)` (não fromSeed): primary=tinta, onPrimary=tintaSobrePrimaria, secondary=margem, onSecondary=papel, tertiary=receita, error=margem, onError=papel, surface=papel, onSurface=tinta, onSurfaceVariant=apagado, surfaceContainerLowest..Highest = tons de papel/papelClaro/papelChip (sem translucidez), outline=tinta, outlineVariant=divisor, primaryContainer=papelChip, onPrimaryContainer=tinta, secondaryContainer = margem com alpha baixo opaco-composto (ou papelChip), inverseSurface=tinta, onInverseSurface=papel, surfaceTint=Colors.transparent, shadow=Colors.transparent.
    - `scaffoldBackgroundColor: cores.papel` (opaco). `fontFamily: 'Inter'`. `textTheme`: display*/headline*/titleLarge em Fraunces w600 (com fontVariations weight 600 via CadernetaTexto), titleMedium/titleSmall/body*/label* em Inter (fontVariations coerentes: 400 body, 500-600 label/titleMedium), todas com cor tinta/apagado conforme o M3.
    - `pageTransitionsTheme` com `CadernetaPageTransitionsBuilder` envolvendo Cupertino (iOS/macOS) e Zoom (demais), igual ao arranjo atual.
    - Component themes (todos com elevation 0, shadowColor transparente, surfaceTint transparente): appBar (bg papel, foreground tinta, borda inferior 1.5px tinta, titleTextStyle Fraunces itálico 600 ~22); tabBar (indicador tinta 2px, label Inter 600, divider cor divisor); card (cor papelClaro, RoundedRectangleBorder raio 4 + side 1.5 tinta, margin padrão mantida); dialog / bottomSheet / popupMenu (papelClaro opaco, raio 4, side 1.5 tinta; barrier preto 0.35); navigationBar/bottomNavigationBar (papelClaro, indicador papelChip, borda superior quando possível); floatingActionButton (bg tinta, fg papel, elevation 0 em todos os estados, shape RoundedRectangleBorder raio 3 com side 1.5 tinta; `extendedTextStyle` Inter 600); elevatedButton / filledButton (bg tinta, fg tintaSobrePrimaria, raio 3, elevation 0, minimumSize Size.fromHeight(48), texto Inter 600 16); outlinedButton (side 1.5 tinta, fg tinta, raio 3); textButton (fg tinta); chip (bg papelChip, selectedColor tinta, label tinta / selecionado tintaSobrePrimaria via `WidgetStateProperty` ou `secondarySelectedColor`+`checkmarkColor`, shape raio 3 side 1.5 tinta, showCheckmark false); inputDecoration (filled papelClaro, OutlineInputBorder raio 3 com side 1.5 tinta; focused side 2 tinta; error side margem); divider (cor divisor, espessura 1); progressIndicator (color tinta, linearTrackColor trilho, linearMinHeight 8, borderRadius 0); switch/checkbox/radio thumbs e fills em tinta; snackBar (bg tinta, content papel, shape raio 3, elevation 0); listTile tileColor transparente; iconTheme cor tinta. Tudo sem sombra e sem translucidez.
    - Apagar app/lib/theme/glass.dart e app/test/theme/glass_test.dart (git rm). Os usos em home_screen/dashboard_screen serão trocados no Task 3 — para o analyze passar ao fim deste task, fazer já a troca mínima nesses dois arquivos: remover o import de glass, trocar `GlassCard(` por `Card(` (mantendo child/margin) e remover `flexibleSpace: const GlassSurface(...)` e `backgroundColor: Colors.transparent` do AppBar da home. O restante do visual dessas telas é Task 3.
    - app/lib/main.dart: remover import de glass e o `GlassBackground` do `builder:` (retornar `BiometricLockWrapper(child: child ?? const SizedBox.shrink())` direto). Antes de `runApp`, registrar as licenças OFL: `LicenseRegistry.addLicense(() async* { ... })` lendo via `rootBundle.loadString('assets/fonts/OFL-Fraunces.txt')` etc. e emitindo `LicenseEntryWithLineBreaks(['Fraunces'], texto)`, idem Inter e IBM Plex Mono (imports `package:flutter/foundation.dart` já existe; adicionar `package:flutter/services.dart` se preciso).
    - biometric_lock_wrapper.dart: remover import de glass; trocar `body: GlassBackground(` por um fundo OPACO (`ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: ...)`) e garantir `backgroundColor` do Scaffold opaco (privacidade — nada da tela de baixo aparece). Sem mudar textos nem layout; opcionalmente trocar o ícone decorativo da trava por `CarimboLogo` SÓ se ele for puramente decorativo e nenhum teste o procurar (conferir `grep -rn "Icons\." test/features/seguranca`); caso contrário manter.
  </action>
  <verify>
    <automated>cd app && flutter analyze && flutter test</automated>
  </verify>
  <done>`grep -rn "Glass\|glass.dart\|BackdropFilter" app/lib app/test` retorna nada; tema claro e escuro usam papel/tinta Caderneta com fontes locais; scaffold e trava biométrica opacos; licenças OFL registradas; analyze sem erros/warnings novos; todos os testes passam.</done>
</task>

<task type="auto">
  <name>Task 3: Telas-chave no estilo Caderneta (hero pautado, carimbo MB, mic com anel duplo, paleta de gráficos, verdes de receita)</name>
  <files>app/lib/features/dashboard/presentation/home_screen.dart, app/lib/features/dashboard/presentation/dashboard_screen.dart, app/lib/features/ditado/presentation/lancamento_ditado_screen.dart, app/lib/features/auth/presentation/login_screen.dart, app/lib/features/relatorios/presentation/widgets/comparativo_mensal_chart.dart, app/lib/features/relatorios/presentation/relatorios_screen.dart, app/lib/features/dashboard/presentation/historico_meses_screen.dart, app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart, app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart, app/lib/features/open_finance/presentation/open_finance_screen.dart, app/lib/features/investimentos/presentation/investimentos_screen.dart, app/lib/features/investimentos/presentation/rebalanceamento_dialog.dart, app/lib/features/metas/presentation/metas_screen.dart</files>
  <action>
    Só visual — nenhuma string, rota, provider, lógica ou `Icons.*` existente muda (testes buscam `Icons.mic_none`, textos etc.).
    - home_screen.dart: no título do AppBar trocar `Icon(Icons.account_balance_wallet_outlined)` por `CarimboLogo(tamanho: 30)` (conferir antes com `grep -rn account_balance_wallet app/test` — hoje nenhum teste usa) e o texto 'Meu Bolso' passa a usar `CadernetaTexto.display(size: 22, italico: true)` na cor tinta. AppBar herda o tema (sem flexibleSpace).
    - dashboard_screen.dart: `_CardGastosMes` (hero "Saldo do mês") vira `PapelPautado(padding: EdgeInsets.fromLTRB(20,16,16,16), child: ...)` (per locked decision: papel pautado + margem dupla vermelha), valor do saldo em `CadernetaTexto.numero(size: 34)` (cor receita se positivo, margem se negativo — trocar `Colors.green.shade700` por `Caderneta.corReceita(context)` e erro por `CadernetaCores.of(context).margem`). O segundo card (linha ~232) fica `Card` do tema. Mapa de cores por categoria (linhas 21-29): substituir as cores Material pela `Caderneta.paletaCategorias(brightness)` — como o mapa é const top-level, trocar por função `Color corDaCategoria(String categoria, Brightness b)` que indexa a paleta pela ordem fixa das categorias ('Alimentação','Transporte','Moradia','Saúde','Lazer','Educação','Mercado','Assinaturas','Outros'; desconhecida → última/ardósia). Atualizar todos os usos do mapa no arquivo (grep o nome do mapa, inclusive fora do arquivo). Metas: `Colors.green.shade600` → corReceita, `Colors.amber.shade700` → ocre #8a6d2f (claro) / variante clara no escuro (pegar da paleta). Valores monetários exibidos no dashboard usam `CadernetaTexto.numero` quando for troca direta de TextStyle (não reestruturar widgets). `Icons.auto_awesome color: Colors.amber` → cor ocre da paleta.
    - lancamento_ditado_screen.dart `_BotaoMic`: círculo preenchido tinta (primary) com ícone papel; anel duplo = Container externo circular com borda 1.5px tinta, padding 6 de papel (cor scaffoldBackground) envolvendo o círculo — equivalente ao `0 0 0 6px papel, 0 0 0 7.5px ink` do sketch. Estado gravando continua usando `colorScheme.error` (agora vermelho de margem). Sem BoxShadow/glow; se houver animação de pulso existente, manter mas sem sombra. Não mudar ícones.
    - login_screen.dart: trocar o ícone-logo `Icons.account_balance_wallet_outlined` (linha ~62) por `CarimboLogo(tamanho: 72)` se nenhum teste o procurar (grep em app/test/features/auth); título do app em `CadernetaTexto.display`. Não mudar textos.
    - Gráficos: comparativo_mensal_chart.dart — barras de receita `Colors.green.shade600` → corReceita, despesa → margem (vermelho) ou tinta conforme o que hoje é despesa; barras com cantos retos (borderRadius 0-2), grid/bordas na cor divisor. relatorio_cartoes_widget.dart — `Color(0xFF0B7A4B)` → tinta (colorScheme.primary), `Color(0xFF32BCAD)` → cor da paleta (ex.: ardósia) via `Caderneta.paletaCategorias`. Qualquer PieChart/BarChart nesses arquivos que usa as cores de categoria passa a usar `corDaCategoria`.
    - Verdes de receita restantes: em historico_meses_screen.dart, relatorios_screen.dart, lancamentos_list_screen.dart, investimentos_screen.dart trocar `Colors.green.shade600/700/800` → `Caderneta.corReceita(context)` e `Colors.green.shade100` / `Colors.green.withValues(alpha: 0.15)` → `Caderneta.corReceitaFundo(context)` (remover `const` onde necessário). `Colors.red` em lancamentos_list_screen:198 (botão excluir) → `Theme.of(context).colorScheme.error`. metas_screen.dart:174-175 e rebalanceamento_dialog.dart: aplicar a mesma troca (verde → corReceita/corReceitaFundo, amber → ocre da paleta) — são troca mecânica de cor, sem mexer em layout.
    - Translucência residual: lancamentos_list_screen.dart:146 e open_finance_screen.dart:511 remover `.withValues(alpha: 0.5)` (painel opaco `surfaceContainerHighest`, que agora é papelChip). Em lancamentos_list_screen:152 o `fontFamily: 'monospace'` vira `'IBMPlexMono'`.
    - Rodar `dart format` só nos arquivos alterados.
  </action>
  <verify>
    <automated>cd app && flutter analyze && flutter test && ! grep -rn "Colors.green\|0xFF0B7A4B\|0xFF32BCAD\|withValues(alpha: 0.5)" lib/features/dashboard lib/features/relatorios/presentation lib/features/lancamentos/presentation lib/features/investimentos/presentation/investimentos_screen.dart lib/features/open_finance/presentation/open_finance_screen.dart</automated>
  </verify>
  <done>Home e login mostram o carimbo MB; hero de saldo é papel pautado com margem dupla vermelha e valor em IBM Plex Mono; mic do ditado é círculo tinta com anel duplo; gráficos e cores de categoria usam a paleta Caderneta; verdes de receita usam o verde Caderneta (claro/noturno); nenhuma translucidez residual; analyze sem erros/warnings novos e todos os testes passam.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| app UI → tela de outro estado | tela de bloqueio biométrico sobreposta ao conteúdo financeiro |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-jxk-01 | Information Disclosure | biometric_lock_wrapper.dart | mitigate | fundo da trava é ColoredBox opaco (scaffoldBackgroundColor) — nada translúcido; rotas também ganham fundo opaco via CadernetaPageTransitionsBuilder |
| T-jxk-02 | Tampering | assets de fonte | accept | fontes OFL baixadas das fontes oficiais, sem pacote novo; nenhum npm/pub install novo |
| T-jxk-03 | Repudiation/Legal | licenças OFL | mitigate | OFL-*.txt commitados como assets e registrados via LicenseRegistry.addLicense |
</threat_model>

<verification>
- `cd app && flutter analyze` sem erros/warnings novos (infos de deprecação pré-existentes toleradas).
- `cd app && flutter test` — suíte inteira verde (231 anteriores − 6 do glass_test + novos do caderneta_test).
- `grep -rn "BackdropFilter\|Glass" app/lib app/test` vazio.
- `git status` mostra app/assets/fonts/* adicionados.
</verification>

<success_criteria>
- Visual Caderneta aplicado globalmente (claro e noturno), opaco, sem sombras/blur, bordas 1.5px e raios 3-4px.
- Fraunces/Inter/IBM Plex Mono empacotadas e com peso correto (fontVariations).
- Hero pautado com margem vermelha, carimbo MB, mic com anel duplo, paleta de gráficos Caderneta.
- Seletor de tema segue funcionando; trava biométrica opaca.
- Textos, ícone do app e widget de tela inicial intocados.
- Commits: `feat(ui): fontes e tokens da identidade Caderneta`, `feat(ui): tema Caderneta global e remocao do vidro`, `feat(ui): telas no estilo Caderneta`.
</success_criteria>

<output>
Create `.planning/quick/260930-jxk-tema-caderneta-no-app/260930-jxk-SUMMARY.md` when done
</output>
