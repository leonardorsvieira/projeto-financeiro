---
phase: quick-260930-qmc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - app/pubspec.yaml
  - app/pubspec.lock
  - app/lib/theme/icones.dart
  - app/lib/theme/app_theme.dart
  - app/lib/theme/theme_selector_dialog.dart
  - app/test/theme/icones_test.dart
  - app/lib/features/auth/presentation/login_screen.dart
  - app/lib/features/auth/presentation/signup_screen.dart
  - app/lib/features/auth/presentation/splash_screen.dart
  - app/lib/features/cartoes/presentation/cartoes_screen.dart
  - app/lib/features/dashboard/presentation/dashboard_screen.dart
  - app/lib/features/dashboard/presentation/historico_meses_screen.dart
  - app/lib/features/dashboard/presentation/home_screen.dart
  - app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart
  - app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart
  - app/lib/features/ditado/presentation/lancamento_ditado_screen.dart
  - app/lib/features/investimentos/presentation/investimento_detalhe_screen.dart
  - app/lib/features/investimentos/presentation/investimentos_screen.dart
  - app/lib/features/investimentos/presentation/rebalanceamento_dialog.dart
  - app/lib/features/lancamentos/presentation/lancamento_form_screen.dart
  - app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart
  - app/lib/features/lancamentos/presentation/lembretes_preferencias_dialog.dart
  - app/lib/features/lancamentos/presentation/proximos_vencimentos_screen.dart
  - app/lib/features/metas/presentation/metas_screen.dart
  - app/lib/features/open_finance/presentation/open_finance_screen.dart
  - app/lib/features/open_finance/presentation/widgets/conectar_banco_dialog.dart
  - app/lib/features/open_finance/presentation/widgets/status_pluggy_dialog.dart
  - app/lib/features/relatorios/presentation/relatorios_screen.dart
  - app/lib/features/seguranca/presentation/biometric_lock_wrapper.dart
  - app/lib/features/seguranca/presentation/bloqueio_biometrico_dialog.dart
  - app/test/features/ditado/presentation/confirmacao_ditado_screen_test.dart
  - app/test/features/ditado/presentation/ditado_flow_test.dart
  - app/test/features/ditado/presentation/lancamento_ditado_screen_test.dart
  - app/test/features/investimentos/presentation/investimentos_screen_test.dart
  - app/test/features/lancamentos/presentation/lancamentos_flow_test.dart
  - app/test/features/lancamentos/presentation/lembretes_preferencias_dialog_test.dart
  - app/test/features/lancamentos/presentation/proximos_vencimentos_screen_test.dart
  - app/test/features/metas/presentation/metas_screen_test.dart
autonomous: true
requirements: [QUICK-260930-qmc]

must_haves:
  truths:
    - "Todas as telas do app (login, cadastro, splash, resumo, livro-caixa, ditado, confirmação, formulário, vencimentos, metas, cartões, relatórios, histórico, investimentos, Open Finance, biometria, aparência) mostram ícones Phosphor Duotone: contorno de tinta + preenchimento suave na mesma cor"
    - "Nenhum `Icons.*` do Material nem `Icon(` puro resta em app/lib — todo ícone é `PhosphorIcon(Icones.<papel>)`"
    - "Os ícones ficam num lugar só: `app/lib/theme/icones.dart` (classe `Icones`, um nome por papel); trocar a família = editar esse arquivo"
    - "Os ícones automáticos do Material também são Phosphor: seta de voltar e X de fechar das AppBars, ⋮ dos PopupMenuButton, seta dos dropdowns e o check do SegmentedButton"
    - "Os fluxos já testados (ditado por voz, lançamento manual, lembretes, próximos vencimentos, metas, investimentos) continuam passando, agora com finders `Icones.*`"
    - "O build web release compila (tree-shaking de ícones com a fonte Phosphor sem erro)"
  artifacts:
    - path: "app/lib/theme/icones.dart"
      provides: "Classe Icones: um static const IconData por papel, todos PhosphorIconsDuotone.*"
      contains: "abstract final class Icones"
    - path: "app/lib/theme/app_theme.dart"
      provides: "actionIconTheme (voltar/fechar/menu lateral) e segmentedButtonTheme.selectedIcon em Phosphor"
      contains: "actionIconTheme"
    - path: "app/test/theme/icones_test.dart"
      provides: "Guarda: Icones só duotone, PhosphorIcon pinta 2 camadas, tema troca voltar/fechar/check, e nenhum Icons./Icon( em lib/"
      contains: "PhosphorIconsDuotone"
  key_links:
    - from: "app/lib/features/**/presentation/*.dart"
      to: "app/lib/theme/icones.dart"
      via: "PhosphorIcon(Icones.<papel>) em vez de Icon(Icons.<material>)"
      pattern: "PhosphorIcon\\(.*Icones\\."
    - from: "app/lib/theme/app_theme.dart"
      to: "ActionIconThemeData / SegmentedButtonThemeData"
      via: "builders que retornam PhosphorIcon(Icones.voltar/fechar/menuLateral) e selectedIcon PhosphorIcon(Icones.confirmar)"
      pattern: "backButtonIconBuilder"
    - from: "PopupMenuButton sem ícone (lancamentos_list, metas, open_finance)"
      to: "Icones.menu"
      via: "icon: const PhosphorIcon(Icones.menu)"
      pattern: "icon: const PhosphorIcon\\(Icones\\.menu\\)"
---

<objective>
Trocar todos os ícones Material do app Flutter Meu Bolso pela família Phosphor Duotone (vencedora do sketch 003, variante A "Traço duplo", SEM o toggle "selo"), centralizando cada papel num único arquivo `app/lib/theme/icones.dart`.

Purpose: os 89 ícones Material "outlined" destoam da Caderneta suave; o Duotone (contorno de tinta + preenchimento suave) conversa com a Fraunces e o carimbo. Centralizar por papel permite trocar a família num lugar só.
Output: `icones.dart` + tema com ícones automáticos em Phosphor + 25 telas migradas + testes atualizados + teste-guarda que impede `Icons.`/`Icon(` voltarem a app/lib.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md
@.planning/sketches/003-icones-caderneta/README.md
@app/lib/theme/app_theme.dart

Estado do repo no planejamento: `app/pubspec.yaml` já tem `phosphor_flutter: ^2.1.0` e `app/pubspec.lock` já foi resolvido (ambos modificados, NÃO commitados). `.claude/` está untracked e NÃO deve ser commitado — sempre `git add` com caminhos explícitos, nunca `git add -A`/`git add .`.

Regras do projeto que valem aqui: código/nomes em português; sem geração de código; NÃO rodar `dart format` em diretórios (o estilo do repo difere) — no máximo em `app/lib/theme/icones.dart` e `app/test/theme/icones_test.dart`, que são novos; diffs mínimos; commits Conventional Commits em português.

<interfaces>
<!-- Extraído do pub cache (phosphor_flutter 2.1.0) e do Flutter 3.47.2. Não é preciso explorar. -->

Import único: `package:phosphor_flutter/phosphor_flutter.dart` (exporta PhosphorIcon, PhosphorIconData, PhosphorDuotoneIconData, PhosphorIconsDuotone).

- `class PhosphorIconsDuotone` — `static const <nome> = PhosphorDuotoneIconData(codePoint, PhosphorIconData(secondaryCodePoint, 'Duotone'))`. Nomes em lowerCamelCase (ex.: `chartDonut`, `calendarDots`, `x`).
- `class PhosphorDuotoneIconData extends PhosphorIconData (extends IconData)` com campo `secondary`.
- `class PhosphorIcon extends Icon` — construtor const: `PhosphorIcon(IconData icon, {Key? key, double? size, double? fill, double? weight, double? grade, double? opticalSize, Color? color, List<Shadow>? shadows, String? semanticLabel, TextDirection? textDirection, double duotoneSecondaryOpacity = 0.20, Color? duotoneSecondaryColor})`. Para ícone duotone, `build` devolve um `Stack` com a camada secundária (`Icon(secondary)` com `Opacity`) + a primária. **Um `Icon(duotoneData)` comum pinta só o contorno** — por isso toda construção vira `PhosphorIcon(`.
- Consequências para testes: `find.byIcon(x)` usa `widget is Icon && widget.icon == x`, então acha o `PhosphorIcon` (1 por ícone; a camada secundária tem outro codePoint e não casa). `find.byType(Icon)` casa só o runtimeType exato `Icon` (= camadas secundárias). Nenhum teste atual usa `byType(Icon)`.
- Todos os usos atuais de `Icon(` em app/lib passam só `size`/`color` (conferido) — todos suportados pelo PhosphorIcon.

Flutter (tema):
- `ThemeData(actionIconTheme: ActionIconThemeData(backButtonIconBuilder:, closeButtonIconBuilder:, drawerButtonIconBuilder:, endDrawerButtonIconBuilder:))` — cada um é `WidgetBuilder?` (`Widget Function(BuildContext)`).
- `ThemeData(segmentedButtonTheme: SegmentedButtonThemeData({ButtonStyle? style, Widget? selectedIcon}))` — `selectedIcon` substitui o `Icon(Icons.check)` padrão do segmento selecionado.
- `PopupMenuButton` sem `icon:`/`child:` desenha `Icon(Icons.adaptive.more)` (= `Icons.more_vert` no Android/testes). Com `icon:` passa a usar o dado.
- `DropdownButtonFormField` sem `icon:` desenha `Icon(Icons.arrow_drop_down)`.

AppTheme (`app/lib/theme/app_theme.dart`): classe `AppTheme` com `static ThemeData get light` / `dark` → `_base(Brightness)`; dentro de `return ThemeData(` já existe `iconTheme: IconThemeData(color: c.tinta),` (≈ linha 120) — inserir os novos temas logo depois dele. Não existe `segmentedButtonTheme` nem `actionIconTheme` hoje.

Estilo de import do projeto: relativo para arquivos do app (ex.: `import '../../../theme/caderneta.dart';`). Profundidade: `lib/features/<f>/presentation/x.dart` → `../../../theme/icones.dart`; `lib/features/open_finance/presentation/widgets/x.dart` → `../../../../theme/icones.dart`; `lib/theme/theme_selector_dialog.dart` → `icones.dart`. Testes usam `package:meubolso/...` (ex.: `import 'package:meubolso/theme/icones.dart';`).
</interfaces>

<icon_map>
<!-- Mapa papel → Phosphor Duotone. TODOS os nomes Phosphor abaixo foram conferidos em phosphor_icons_duotone.dart (2.1.0). -->
<!-- Coluna "Substitui" = Material que vira esse papel (mapeamento padrão). Exceções por linha em <overrides>. -->

| Papel (`Icones.`) | `PhosphorIconsDuotone.` | Substitui (`Icons.`) |
|---|---|---|
| **Navegação / abas / menus** | | |
| resumo | chartDonut | space_dashboard_outlined |
| livroCaixa | notebook | list_alt_outlined, receipt_long_outlined |
| menu | dotsThreeVertical | more_vert (+ PopupMenuButton sem ícone) |
| voltar | arrowLeft | (tema: backButtonIconBuilder) |
| menuLateral | list | (tema: drawer/endDrawerButtonIconBuilder) |
| anterior | caretLeft | chevron_left |
| proximo | caretRight | chevron_right |
| abrirLista | caretDown | (seta de DropdownButtonFormField) |
| hoje | calendarDot | today |
| **Dinheiro** | | |
| sobe | trendUp | trending_up |
| desce | trendDown | trending_down |
| rendimento | chartLineUp | (override investimentos_screen:341) |
| entrada | arrowCircleDown | arrow_downward |
| valor | currencyCircleDollar | attach_money |
| formaPagamento | money | payments_outlined |
| carteira | wallet | account_balance_wallet_outlined |
| cartao | creditCard | credit_card, credit_card_outlined |
| semCartao | cards | credit_card_off_outlined |
| banco | bank | account_balance, account_balance_outlined |
| pix | lightning | flash_on |
| tempoReal | lightning | bolt |
| patrimonio | chartPieSlice | pie_chart_outline |
| distribuicao | chartPieSlice | (override relatorio_cartoes_widget:82) |
| meta | target | track_changes_outlined |
| relatorio | chartBar | bar_chart, bar_chart_outlined |
| ranking | ranking | leaderboard |
| categoria | shapes | category, category_outlined |
| rebalancear | scales | balance |
| trofeu | trophy | emoji_events |
| ajustar | slidersHorizontal | tune |
| **Datas / vencimentos** | | |
| vencimento | calendarDots | schedule_outlined, event |
| data | calendarBlank | event_outlined |
| horario | clock | (override lembretes:76) |
| antecedencia | calendarMinus | (override lembretes:96) |
| semVencimentos | calendarCheck | event_available_outlined |
| periodoCurto | calendarBlank | calendar_view_month |
| periodoLongo | calendar | calendar_today |
| historico | clockCounterClockwise | history, history_outlined |
| fixaMensal | repeat | repeat_outlined |
| **Voz** | | |
| ditar | microphone | mic, mic_none |
| pararGravacao | stop | stop |
| processando | hourglassHigh | hourglass_top |
| **Ações** | | |
| adicionar | plus | add |
| aumentar | plusCircle | add_circle_outline |
| remover | minusCircle | remove_circle_outline |
| fechar | x | close (+ tema: closeButtonIconBuilder) |
| limpar | xCircle | clear |
| confirmar | check | check (+ tema: SegmentedButton selectedIcon) |
| buscar | magnifyingGlass | search |
| sincronizar | arrowsClockwise | sync |
| atualizar | arrowClockwise | refresh |
| excluir | trash | delete_outline |
| editar | pencilSimple | (sem uso hoje — papel pedido na decisão) |
| exportar | downloadSimple | download_outlined |
| importar | fileArrowUp | upload_file, file_upload_outlined |
| pdf | filePdf | picture_as_pdf |
| planilha | fileCsv | table_chart_outlined |
| abrirExterno | arrowSquareOut | open_in_new, launch |
| configuracoes | gearSix | settings_outlined |
| descricao | notePencil | description_outlined |
| item | basket | shopping_basket_outlined |
| **Open Finance** | | |
| conectarNuvem | cloudArrowUp | cloud_sync |
| semConexao | cloudSlash | cloud_off, cloud_off_outlined |
| conectado | link | link |
| desconectar | linkBreak | link_off |
| chave | key | vpn_key_outlined |
| codigo | hash | tag |
| pin | password | pin_outlined |
| verificado | shieldCheck | verified_user |
| **Conta / segurança** | | |
| email | envelopeSimple | mail_outline |
| emailConfirmado | envelopeSimpleOpen | mark_email_read_outlined |
| senha | lockKey | lock_outline |
| verSenha | eye | visibility_outlined |
| ocultarSenha | eyeSlash | visibility_off_outlined |
| seguranca | lockSimple | (override home_screen:189) |
| biometria | fingerprint | fingerprint |
| desbloquear | lockSimpleOpen | lock_open |
| aviso | warning | warning_amber_rounded |
| sair | signOut | logout |
| **Aparência / avisos / IA** | | |
| tema | palette | palette_outlined |
| temaSistema | circleHalf | brightness_auto_outlined |
| temaClaro | sun | light_mode_outlined |
| temaEscuro | moon | dark_mode_outlined |
| notificacao | bell | notifications_outlined |
| testarNotificacao | bellRinging | notifications_active_outlined |
| ia | sparkle | auto_awesome |
| analisar | brain | psychology_outlined |
| **Categorias (sketch 003)** | | |
| alimentacao | forkKnife | — |
| transporte | carProfile | — |
| moradia | houseLine | — |
| saude | firstAidKit | — |
| lazer | filmSlate | — |
| educacao | graduationCap | — |
| mercado | basket | — |
| assinaturas | repeat | — |
| outros | dotsThreeCircle | — |

Cobertura: as 89 constantes `Icons.*` distintas usadas hoje em app/lib aparecem todas na coluna "Substitui".

<overrides>
Exceções por linha (números conferidos no HEAD atual — reconfirmar com `grep -n` antes de aplicar; aplicar ANTES do mapeamento padrão):
- app/lib/features/lancamentos/presentation/lembretes_preferencias_dialog.dart:76 `Icons.schedule_outlined` ("Horário do aviso") → `Icones.horario`
- app/lib/features/lancamentos/presentation/lembretes_preferencias_dialog.dart:96 `Icons.event_outlined` ("Avisar dias antes") → `Icones.antecedencia`
- app/lib/features/dashboard/presentation/home_screen.dart:154 `Icons.event_outlined` (menu "Próximos vencimentos") → `Icones.vencimento`
- app/lib/features/dashboard/presentation/home_screen.dart:189 `Icons.fingerprint` (menu "Segurança e biometria", como no sketch) → `Icones.seguranca`
- app/lib/features/investimentos/presentation/investimentos_screen.dart:341 `Icons.trending_up` (avatar do investimento) → `Icones.rendimento`
- app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart:82 `Icons.pie_chart_outline` ("Despesas por forma de pagamento") → `Icones.distribuicao`
</overrides>
</icon_map>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Classe Icones (Phosphor Duotone) + ícones automáticos no AppTheme</name>
  <files>app/lib/theme/icones.dart, app/lib/theme/app_theme.dart, app/test/theme/icones_test.dart, app/pubspec.yaml, app/pubspec.lock</files>
  <behavior>
    - Teste 1: todas as linhas `static const` de `lib/theme/icones.dart` apontam para `PhosphorIconsDuotone.` (lê o arquivo com dart:io, cwd do `flutter test` = app/) e existem pelo menos 80 papéis.
    - Teste 2: `Icones.ditar`, `Icones.resumo`, `Icones.voltar` são `PhosphorDuotoneIconData` (isA).
    - Teste 3: `PhosphorIcon(Icones.ditar)` dentro de `Directionality` pinta 2 camadas: `find.byWidgetPredicate((w) => w is Icon)` → 2 widgets; `find.byIcon(Icones.ditar)` → 1.
    - Teste 4: `MaterialApp(theme: AppTheme.light, home: Scaffold(appBar: AppBar(leading: BackButton(), actions: [CloseButton()])))` → `find.byIcon(Icones.voltar)` e `find.byIcon(Icones.fechar)` achando 1 cada; idem com `AppTheme.dark`.
    - Teste 5: com `AppTheme.light`, um `SegmentedButton<int>` com um segmento selecionado mostra `find.byIcon(Icones.confirmar)` → 1.
  </behavior>
  <action>
RED: criar `app/test/theme/icones_test.dart` com os 5 testes acima (imports: flutter/material, flutter_test, dart:io, phosphor_flutter, `package:meubolso/theme/icones.dart`, `package:meubolso/theme/app_theme.dart`) e rodar — deve falhar (arquivo icones.dart ainda não existe).

GREEN:
1. Criar `app/lib/theme/icones.dart`: importa `package:flutter/widgets.dart` e `package:phosphor_flutter/phosphor_flutter.dart`; declara `abstract final class Icones` com um `static const IconData <papel> = PhosphorIconsDuotone.<nome>;` para CADA linha da tabela `<icon_map>` (todas as seções, inclusive categorias e `editar`), agrupadas com comentários curtos em português por seção (Navegação, Dinheiro, Datas, Voz, Ações, Open Finance, Conta, Aparência/IA, Categorias). Doc comment no topo da classe (português): família Phosphor Duotone escolhida no sketch 003; renderizar SEMPRE com `PhosphorIcon(...)` (um `Icon` comum pinta só o contorno); para trocar a família, mudar só este arquivo. Não criar widget wrapper nem helper de opacidade — decisão de discrição: usar a opacidade padrão do pacote (0.20) na camada de preenchimento, mantendo toda construção como `PhosphorIcon(...)` simples (per locked decision "keep it simple"). Categorias e `editar` ficam definidos porque a decisão os nomeia como papéis; nenhuma tela desenha ícone por categoria hoje, então não têm chamadas nesta tarefa.
2. Em `app/lib/theme/app_theme.dart`: adicionar `import 'package:phosphor_flutter/phosphor_flutter.dart';` e `import 'icones.dart';`. Dentro do `ThemeData(` de `_base`, logo após `iconTheme: IconThemeData(color: c.tinta),`, adicionar (per locked decision de ícones automáticos): `actionIconTheme: ActionIconThemeData(...)` com `backButtonIconBuilder` → `const PhosphorIcon(Icones.voltar)`, `closeButtonIconBuilder` → `const PhosphorIcon(Icones.fechar)`, `drawerButtonIconBuilder` e `endDrawerButtonIconBuilder` → `const PhosphorIcon(Icones.menuLateral)` (closures `(_) => ...`); e `segmentedButtonTheme: const SegmentedButtonThemeData(selectedIcon: PhosphorIcon(Icones.confirmar))`. Não mexer em mais nada do tema. Sem tamanho/cor explícitos — herdam do IconTheme como os ícones padrão.
3. Rodar o teste até passar; `flutter analyze` limpo.
4. Commit (inclui o pubspec que já estava modificado, per locked decision): `git add app/pubspec.yaml app/pubspec.lock app/lib/theme/icones.dart app/lib/theme/app_theme.dart app/test/theme/icones_test.dart` e mensagem `feat(ui): classe Icones com Phosphor Duotone e ícones automáticos do tema`.
  </action>
  <verify>
    <automated>cd app && flutter test test/theme/icones_test.dart && flutter analyze lib/theme test/theme</automated>
  </verify>
  <done>`app/lib/theme/icones.dart` existe com `abstract final class Icones` e todos os papéis do `<icon_map>` apontando para `PhosphorIconsDuotone.*`; AppTheme tem `actionIconTheme` e `segmentedButtonTheme`; os 5 testes de `icones_test.dart` passam; analyze sem issues; commit feito com pubspec.yaml/lock.</done>
</task>

<task type="auto">
  <name>Task 2: Codemod — trocar Icons.*/Icon( por PhosphorIcon(Icones.*) nas 25 telas + testes</name>
  <files>app/lib/features/auth/presentation/login_screen.dart, app/lib/features/auth/presentation/signup_screen.dart, app/lib/features/auth/presentation/splash_screen.dart, app/lib/features/cartoes/presentation/cartoes_screen.dart, app/lib/features/dashboard/presentation/dashboard_screen.dart, app/lib/features/dashboard/presentation/historico_meses_screen.dart, app/lib/features/dashboard/presentation/home_screen.dart, app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart, app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart, app/lib/features/ditado/presentation/lancamento_ditado_screen.dart, app/lib/features/investimentos/presentation/investimento_detalhe_screen.dart, app/lib/features/investimentos/presentation/investimentos_screen.dart, app/lib/features/investimentos/presentation/rebalanceamento_dialog.dart, app/lib/features/lancamentos/presentation/lancamento_form_screen.dart, app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart, app/lib/features/lancamentos/presentation/lembretes_preferencias_dialog.dart, app/lib/features/lancamentos/presentation/proximos_vencimentos_screen.dart, app/lib/features/metas/presentation/metas_screen.dart, app/lib/features/open_finance/presentation/open_finance_screen.dart, app/lib/features/open_finance/presentation/widgets/conectar_banco_dialog.dart, app/lib/features/open_finance/presentation/widgets/status_pluggy_dialog.dart, app/lib/features/relatorios/presentation/relatorios_screen.dart, app/lib/features/seguranca/presentation/biometric_lock_wrapper.dart, app/lib/features/seguranca/presentation/bloqueio_biometrico_dialog.dart, app/lib/theme/theme_selector_dialog.dart, app/test/features/ditado/presentation/confirmacao_ditado_screen_test.dart, app/test/features/ditado/presentation/ditado_flow_test.dart, app/test/features/ditado/presentation/lancamento_ditado_screen_test.dart, app/test/features/investimentos/presentation/investimentos_screen_test.dart, app/test/features/lancamentos/presentation/lancamentos_flow_test.dart, app/test/features/lancamentos/presentation/lembretes_preferencias_dialog_test.dart, app/test/features/lancamentos/presentation/proximos_vencimentos_screen_test.dart</files>
  <action>
Migração mecânica (per locked decision "Replace EVERY Icons.* … Every Icon( becomes PhosphorIcon("). São ~160 ocorrências em 25 arquivos: fazer por script (GNU sed do Git Bash, arquivo de script no scratchpad), NÃO com uma edição manual por ocorrência. Os 25 arquivos são exatamente os que `grep -rlE "Icons\." app/lib` lista hoje (o mesmo conjunto tem `Icon(`).

1. Overrides primeiro: reconfirmar com `grep -n` as 6 linhas de `<overrides>` e aplicar substituições endereçadas por linha (`sed -i 'NNNs/Icons\.x\b/Icones.y/'`). Os números não mudam depois, pois nenhuma substituição altera a contagem de linhas.
2. Mapeamento padrão: para cada linha da tabela `<icon_map>` com coluna "Substitui", aplicar `s/\bIcons\.<material>\b/Icones.<papel>/g` nos 25 arquivos. O `\b` final evita que `Icons.add` pegue `Icons.add_circle_outline`, `Icons.event` pegue `event_outlined`, `Icons.credit_card` pegue `credit_card_outlined`, `Icons.link` pegue `link_off`, `Icons.mic` pegue `mic_none`, `Icons.account_balance` pegue `account_balance_outlined`, etc.
3. Construtores: nos mesmos 25 arquivos, `s/\bIcon(/PhosphorIcon(/g` (inclui `const Icon(`, `Icon(` no fim da linha, e os widgets que recebem `IconData` e desenham internamente: `_Badge` em lancamentos_list_screen:440 e proximos_vencimentos_screen:160, o botão grande em lancamento_ditado_screen:194 e `destaque` em investimentos_screen:259). `\bIcon(` não casa `PhosphorIcon(` nem `ImageIcon(`. Constância preservada: `PhosphorIcon` tem construtor const e `Icones.*` são const, então `const InputDecoration(prefixIcon: PhosphorIcon(...))`, `const Tab(...)` etc. continuam válidos. Manter tamanhos/cores exatamente como estão.
4. Imports: em cada um dos 25 arquivos adicionar `import 'package:phosphor_flutter/phosphor_flutter.dart';` (junto dos outros `package:`) e o import relativo de `icones.dart` com a profundidade certa (ver `<interfaces>`: `../../../theme/icones.dart`; `../../../../theme/icones.dart` em `open_finance/presentation/widgets/`; `icones.dart` em `lib/theme/theme_selector_dialog.dart`). Se `material.dart` só era usado por `Icons` num arquivo, o analyze avisará — não remova sem o aviso.
5. Testes (mesmo commit, para a suíte seguir verde): nos 7 arquivos abaixo trocar os finders e adicionar `import 'package:meubolso/theme/icones.dart';`:
   - app/test/features/ditado/presentation/confirmacao_ditado_screen_test.dart, ditado_flow_test.dart, lancamento_ditado_screen_test.dart: `Icons.mic_none`→`Icones.ditar`, `Icons.stop`→`Icones.pararGravacao` (índices `.at(0/1/2)` continuam iguais: nada mais nessas telas vira microphone).
   - app/test/features/investimentos/presentation/investimentos_screen_test.dart: `Icons.sync`→`Icones.sincronizar`.
   - app/test/features/lancamentos/presentation/lancamentos_flow_test.dart: `Icons.add`→`Icones.adicionar`.
   - app/test/features/lancamentos/presentation/lembretes_preferencias_dialog_test.dart: `Icons.more_vert`→`Icones.menu`, `Icons.add_circle_outline`→`Icones.aumentar`, `Icons.remove_circle_outline`→`Icones.remover`.
   - app/test/features/lancamentos/presentation/proximos_vencimentos_screen_test.dart: `Icons.more_vert`→`Icones.menu` (é o menu do HomeScreen).
   - NÃO mexer em app/test/features/metas/presentation/metas_screen_test.dart nesta tarefa: o ⋮ da MetasScreen ainda é o ícone padrão do PopupMenuButton (`Icons.more_vert`) até a Task 3.
   Se algum teste passar a achar 2 widgets porque dois Material distintos viraram o mesmo glifo (ex.: FAB "Ditar" do home + microfone da tela de ditado, ambos `Icones.ditar`), estreitar o finder com `find.descendant(of: find.byType(<Tela>), matching: ...)` — não mudar o mapa.
6. Gates: `grep -rE "\bIcons\." app/lib --include=*.dart | grep -vE ":\s*//"` e `grep -rE "(^|[^A-Za-z0-9_])Icon\(" app/lib --include=*.dart | grep -vE ":\s*//"` devem sair vazios; `flutter analyze` sem issues; `flutter test` inteiro verde. Não rodar `dart format` nesses arquivos (conferir `git diff --stat`: só linhas de ícone/import mudaram).
7. Commit só com os 25 arquivos de lib + 7 testes (caminhos explícitos): `feat(ui): telas com ícones Phosphor Duotone via Icones`.
  </action>
  <verify>
    <automated>cd app && test -z "$(grep -rE '\bIcons\.' lib --include=*.dart | grep -vE ':\s*//')" && test -z "$(grep -rE '(^|[^A-Za-z0-9_])Icon\(' lib --include=*.dart | grep -vE ':\s*//')" && flutter analyze && flutter test</automated>
  </verify>
  <done>Zero `Icons.` e zero `Icon(` puro em app/lib (fora de comentários); os 25 arquivos importam phosphor_flutter + icones.dart; os 6 overrides aplicados; os 7 testes usam `Icones.*`; `flutter analyze` sem issues e `flutter test` inteiro passando; commit feito.</done>
</task>

<task type="auto">
  <name>Task 3: Ícones padrão escondidos (⋮ e seta de dropdown) + guarda anti-regressão + build web release</name>
  <files>app/lib/features/lancamentos/presentation/lancamentos_list_screen.dart, app/lib/features/metas/presentation/metas_screen.dart, app/lib/features/open_finance/presentation/open_finance_screen.dart, app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart, app/lib/features/lancamentos/presentation/lancamento_form_screen.dart, app/lib/features/open_finance/presentation/widgets/conectar_banco_dialog.dart, app/test/features/metas/presentation/metas_screen_test.dart, app/test/theme/icones_test.dart</files>
  <action>
Ícones que o Material desenha sozinho sem aparecer como `Icons.` no código (discrição do planner, estendendo a decisão "make Material's automatic icons match"):
1. PopupMenuButton sem ícone — adicionar `icon: const PhosphorIcon(Icones.menu),` logo após a linha `tooltip:` de: lancamentos_list_screen.dart (~l.388, tooltip 'Ações'), metas_screen.dart (~l.202, tooltip 'Ações'), open_finance_screen.dart (~l.693, `trailing: PopupMenuButton`, tooltip 'Opções'). Nenhum deles usa `child:` (conferido), então `icon:` é permitido.
2. DropdownButtonFormField — adicionar `icon: const PhosphorIcon(Icones.abrirLista),` nos 6 usos: confirmacao_ditado_screen.dart (~l.443 e ~l.468), lancamento_form_screen.dart (~l.395 e ~l.425), metas_screen.dart (~l.309), conectar_banco_dialog.dart (~l.487). Nenhum passa `icon:` hoje. Todos esses arquivos já importam phosphor_flutter/icones.dart desde a Task 2.
3. app/test/features/metas/presentation/metas_screen_test.dart: `Icons.more_vert`→`Icones.menu` + `import 'package:meubolso/theme/icones.dart';`.
4. Guarda anti-regressão em app/test/theme/icones_test.dart — novo `group('lib sem ícones Material', ...)`: percorre `Directory('lib')` recursivamente (arquivos .dart), ignora linhas cujo trim começa com `//`, e falha listando `arquivo:linha` se achar `RegExp(r'\bIcons\.')` ou `RegExp(r'(?<![A-Za-z0-9_])Icon\(')`. Um segundo teste: todo `PopupMenuButton<` em lib/ tem um `icon:` ou `child:` nas 6 linhas seguintes (para o ⋮ não voltar a ser Material). Sem allowlist; se um caso realmente impossível aparecer, adicionar allowlist explícita com comentário do motivo e registrar no SUMMARY.
5. Exceções conhecidas (registrar no SUMMARY, não tentar trocar): ícones internos do `showDatePicker`/`showTimePicker` (editar/teclado/setas de mês), a seta animada do `ExpansionTile` em conectar_banco_dialog (trocar por `trailing:` perderia a rotação), e checkmarks pintados de `CheckboxListTile`/`FilterChip` (não são ícones). Fora de escopo por decisão: widget Android, ícone do launcher, ícones do PDF, CarimboLogo.
6. `flutter analyze` + `flutter test` inteiro verdes; depois `flutter build web --release` (timeout 10 min) para provar que o tree-shaking de ícones aceita a fonte Phosphor (todas as `IconData` são const). Se o build falhar por `IconData` não-const em código do app, corrigir; se a falha vier do próprio pacote, NÃO adicionar `--no-tree-shake-icons` em workflows/scripts — registrar o erro exato no SUMMARY como bloqueio. Não commitar nada de `app/build/`.
7. Commit (caminhos explícitos): `feat(ui): menus, dropdowns e guarda de ícones Phosphor`.
  </action>
  <verify>
    <automated>cd app && test -z "$(grep -rE '\bIcons\.' lib test --include=*.dart | grep -vE ':\s*//')" && flutter analyze && flutter test && flutter build web --release</automated>
  </verify>
  <done>Os 3 PopupMenuButton usam `PhosphorIcon(Icones.menu)` e os 6 dropdowns `PhosphorIcon(Icones.abrirLista)`; nenhum `Icons.` em app/lib nem app/test; o grupo-guarda em icones_test.dart passa; analyze sem issues; suíte inteira verde; `flutter build web --release` conclui; commit feito; exceções documentadas no SUMMARY.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| pub.dev → build | Dependência nova `phosphor_flutter` (fontes + Dart) entra no bundle web público e nos APKs |

Mudança puramente visual: nenhum dado, rota, chamada de rede, segredo ou RLS é tocado.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-qmc-SC | Tampering | `phosphor_flutter ^2.1.0` (pubspec) | accept | Adicionado pelo usuário antes do planejamento e já resolvido no `pubspec.lock` (sha256 fixado); é o pacote oficial do projeto Phosphor Icons, só fontes TTF + classes Dart, sem código nativo nem rede. Nenhum outro pacote é instalado neste plano. |
| T-qmc-01 | Information Disclosure | Bundle web / CSP (`app/web/index.html`) | accept | As fontes Phosphor são assets do próprio bundle (`font-src 'self'` já cobre); nenhum domínio novo, CSP inalterada. |
| T-qmc-02 | Denial of Service | Build release (tree-shaking de ícones) | mitigate | Task 3 roda `flutter build web --release`; todas as `IconData` vêm de `static const` em `Icones`, sem `IconData(...)` em runtime. |
</threat_model>

<verification>
- `cd app && flutter analyze` → No issues found.
- `cd app && flutter test` → suíte inteira verde (inclui `test/theme/icones_test.dart` com a guarda de lib/).
- `grep -rE "\bIcons\." app/lib app/test --include=*.dart | grep -vE ":\s*//"` → vazio.
- `cd app && flutter build web --release` → conclui sem erro de tree-shaking.
- `git status` → só `.claude/` untracked sobra; 3 commits `feat(ui): ...` em português.
- Checagem visual (não bloqueante, depois do deploy na web/APK): conferir que os ícones mostram o preenchimento suave (camada duotone) e não só o contorno, no tema claro e no escuro.
</verification>

<success_criteria>
- Nenhum ícone Material `Icons.*` em app/lib; toda construção de ícone é `PhosphorIcon(Icones.<papel>)`.
- `app/lib/theme/icones.dart` é a única fonte dos ícones (todos `PhosphorIconsDuotone.*`, verificado por teste).
- Voltar/fechar da AppBar, ⋮ dos menus, seta dos dropdowns e check do SegmentedButton também em Phosphor.
- `flutter analyze` e `flutter test` passam; build web release compila.
- Exceções (pickers de data/hora, ExpansionTile, checkmarks pintados) e itens fora de escopo registrados no SUMMARY.
</success_criteria>

<output>
Create `.planning/quick/260930-qmc-icones-phosphor-duotone-no-app/260930-qmc-SUMMARY.md` when done
</output>
