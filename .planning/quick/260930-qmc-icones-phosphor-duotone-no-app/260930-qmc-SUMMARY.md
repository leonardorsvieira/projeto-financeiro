---
phase: quick-260930-qmc
plan: 01
status: complete
subsystem: ui
tags: [flutter, icones, phosphor, duotone, tema, caderneta]
requires:
  - sketch 003 (Phosphor Duotone, variante A "Traço duplo")
provides:
  - app/lib/theme/icones.dart (classe Icones, um papel por ícone, + export do PhosphorIcon)
  - app/lib/theme/phosphor_icon.dart (PhosphorIcon local: contorno + preenchimento)
  - ícones automáticos do Material (voltar, fechar, menu lateral, check do SegmentedButton, ⋮, seta de dropdown) em Phosphor
  - teste-guarda impedindo Icons.* / Icon( em app/lib
affects:
  - 25 telas em app/lib (auth, dashboard, ditado, lançamentos, metas, investimentos, Open Finance, relatórios, segurança, aparência)
tech-stack:
  added: []   # phosphor_flutter já estava no pubspec; só as FONTES do pacote são usadas (ver desvio)
  patterns:
    - "Todo ícone é PhosphorIcon(Icones.<papel>); trocar a família = editar icones.dart"
key-files:
  created:
    - app/lib/theme/icones.dart
    - app/lib/theme/phosphor_icon.dart
    - app/test/theme/icones_test.dart
  modified:
    - app/pubspec.yaml
    - app/pubspec.lock
    - app/lib/theme/app_theme.dart
    - app/lib/theme/theme_selector_dialog.dart
    - 24 telas em app/lib/features/**/presentation
    - 8 testes em app/test/features
decisions:
  - "Pacote phosphor_flutter 2.1.0 não compila no Flutter 3.47.2 (IconData virou final class): montar IconData const localmente e usar só as fontes do pacote"
  - "Opacidade da camada de preenchimento = 0.20 (padrão Phosphor); sem wrapper extra além do PhosphorIcon"
metrics:
  tasks: 3
  commits: 3
  completed: 2026-09-30
---

# Quick 260930-qmc: Ícones Phosphor Duotone no app Summary

Todos os ícones Material do app trocados por Phosphor Duotone (contorno de tinta + preenchimento suave a 20%), centralizados por papel em `app/lib/theme/icones.dart`, com os ícones automáticos do Material (voltar, fechar, ⋮, seta de dropdown, check do SegmentedButton) também em Phosphor e um teste-guarda contra regressão.

## Commits

| Task | Commit | Descrição |
|------|--------|-----------|
| 1 | `7ccb3e1` | `feat(ui): classe Icones com Phosphor Duotone e ícones automáticos do tema` (inclui `pubspec.yaml`/`pubspec.lock`) |
| 2 | `f5ae569` | `feat(ui): telas com ícones Phosphor Duotone via Icones` (25 arquivos de lib + 7 testes) |
| 3 | `1a6d484` | `feat(ui): menus, dropdowns e guarda de ícones Phosphor` |

## O que foi feito

- **Task 1:** `Icones` com 96 papéis (todas as linhas do `<icon_map>`, incluindo categorias e `editar`), `AppTheme` com `actionIconTheme` (voltar/fechar/menu lateral) e `segmentedButtonTheme.selectedIcon`, `test/theme/icones_test.dart` (RED antes, depois GREEN).
- **Task 2:** codemod por script (sed): 89 constantes `Icons.*` distintas -> `Icones.<papel>` (6 overrides por linha aplicados antes: horário/antecedência dos lembretes, "Próximos vencimentos" e "Segurança e biometria" do menu, avatar do investimento, "Despesas por forma de pagamento"), `Icon(` -> `PhosphorIcon(` (165 referências a `Icones.*`), import de `icones.dart` em cada arquivo, 7 testes com finders `Icones.*`.
- **Task 3:** `icon: const PhosphorIcon(Icones.menu)` nos 3 `PopupMenuButton` sem ícone (livro-caixa, metas, Open Finance), `icon: const PhosphorIcon(Icones.abrirLista)` nos 6 `DropdownButtonFormField`, `metas_screen_test` com `Icones.menu`, e grupo-guarda em `icones_test.dart` (nenhum `Icons.*`/`Icon(` puro em lib; `PopupMenuButton`/dropdown sempre com ícone próprio). A guarda foi validada por mutação (removendo um `icon:` e trocando um ícone por `Icon(Icons.add)` ela falha; arquivo restaurado depois).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `phosphor_flutter` 2.1.0 não compila com o Flutter do projeto**
- **Found during:** Task 1 (primeira execução do teste GREEN)
- **Issue:** `package:phosphor_flutter/phosphor_flutter.dart` falha na compilação: `The class 'IconData' can't be extended outside of its library because it's a final class` (Flutter 3.47.2 / Dart 3.13.2 marcam `IconData` como `final class`; o pacote faz `PhosphorIconData extends IconData`). 2.1.0 é a última versão no pub.dev, então não havia versão corrigida.
- **Fix:** manter a dependência `phosphor_flutter` apenas pelos **assets de fonte** (`PhosphorDuotone`, `fontPackage: 'phosphor_flutter'`) e não importar o Dart do pacote:
  - `Icones` monta cada papel como `static const IconData(codePoint, fontFamily: 'PhosphorDuotone', fontPackage: 'phosphor_flutter')`, com os códigos extraídos por script de `phosphor_icons_duotone.dart` do pacote (o nome Phosphor fica num comentário acima de cada papel). O glifo de preenchimento não é `codigo - 1` em todos os ícones (`repeat` e `shieldCheck` diferem), então há uma tabela `const Map<int, IconData>` (91 entradas) com o secundário de cada contorno, também em `icones.dart`. Tudo const, como o tree-shaking exige.
  - `PhosphorIcon` local (`app/lib/theme/phosphor_icon.dart`, reexportado por `icones.dart`): mesmo contrato do widget do pacote (estende `Icon`; `Stack` com `Opacity(0.20, Icon(secundário))` + contorno). `find.byIcon(Icones.x)` continua achando 1 widget e há 2 `Icon` por ícone, como o plano previa.
  - Consequência: os arquivos importam só `icones.dart` (não `package:phosphor_flutter/...`), e o teste "todo papel aponta para PhosphorIconsDuotone" virou "todo papel usa a fonte PhosphorDuotone e tem camada de preenchimento".
- **Files modified:** `app/lib/theme/icones.dart`, `app/lib/theme/phosphor_icon.dart`, `app/test/theme/icones_test.dart`
- **Commit:** `7ccb3e1`
- **Reversível:** quando o pacote corrigir o `IconData`, basta trocar o conteúdo de `icones.dart` por `PhosphorIconsDuotone.*` e apagar `phosphor_icon.dart`; as telas não mudam.

**2. [Rule 3 - Blocking] Allowlist no teste-guarda**
- **Issue:** o guarda "nenhum `Icon(` puro em lib" pegaria o próprio `PhosphorIcon` local (que monta o `Icon` da camada de preenchimento).
- **Fix:** allowlist explícita e comentada com um único arquivo, `lib/theme/phosphor_icon.dart`.
- **Commit:** `1a6d484`

**3. [Rule 1 - Bug] Import `material.dart` sem uso**
- `lancamento_ditado_screen_test.dart` só usava `Icons`; o import de `flutter/material.dart` foi removido (aviso do analyze). Commit `f5ae569`.

### Outros desvios menores

- **Atribuição nos commits:** as mensagens terminam com `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` (o modelo que executou), em vez do "Opus 5.5" citado na instrução.
- **Quebra de linha final:** o script que inseriu os imports acrescentou a nova linha final em 11 arquivos de lib/test que não a tinham (aparece como `-}`/`+}` no diff). Sem outra mudança de formatação; `dart format` não foi rodado em nenhum arquivo antigo.
- **Um primeiro sed quebrado** (o shell consumiu as barras invertidas de `\b`) foi detectado antes de qualquer commit; os 25 arquivos foram restaurados com `git checkout -- <arquivo>` e o codemod refeito com o script correto.

## Verificação

- `flutter analyze`: **0 erros, 0 warnings, 9 infos** `deprecated_member_use` que já existiam e não vêm deste trabalho (`RadioListTile.groupValue/onChanged` em `theme_selector_dialog.dart`, `DropdownButtonFormField.value` em `conectar_banco_dialog.dart`, `Table.fromTextArray` em `pdf_report_service.dart`). O critério "No issues found" do plano não é alcançável sem tocar nesses arquivos por outro motivo; fora de escopo.
- `flutter test`: **249 testes passando** (inclui `test/theme/icones_test.dart` com 10 testes).
- `grep -rE "\bIcons\." app/lib app/test` (fora de comentários): vazio. `Icon(` puro em `app/lib`: só o `phosphor_icon.dart` (allowlist).
- `flutter build web --release` (com `--dart-define` falsos de SUPABASE_URL/ANON_KEY): **concluído** em ~186 s. Tree-shaking: `Phosphor-Duotone.ttf` 567.808 -> 32.336 bytes (cabe ~182 glifos = 91 contornos + 91 preenchimentos), MaterialIcons 1,6 MB -> 8 KB. Nada de `app/build/` foi commitado.
- `git status`: só `.claude/` e este diretório de planejamento ficaram sem commit; nenhum `git add -A`; nenhum push.

## Exceções conhecidas (não trocadas, por decisão do plano)

- Ícones internos do `showDatePicker`/`showTimePicker` (editar/teclado/setas de mês) - usados em confirmação do ditado, formulário de lançamento, cartões e diálogo de lembretes.
- Seta animada do `ExpansionTile` em `conectar_banco_dialog.dart` (trocar por `trailing:` perderia a rotação).
- Checkmarks pintados de `CheckboxListTile` e `FilterChip` (não são ícones).
- Fora de escopo: widget Android, ícone do launcher, ícones do PDF, CarimboLogo.
- Papéis sem uso em tela hoje: categorias (alimentacao ... outros) e `editar` ficam definidos em `Icones` como a decisão pediu.

## Pontos de atenção / follow-ups

- **Tamanho do bundle:** o pacote declara as 6 fontes Phosphor no pubspec e o Flutter embute todas; só a Duotone passa pelo tree-shaking. As outras cinco (Bold, Fill, Light, Thin, Regular; ~2,5 MB no total) vão inteiras para o web e para o APK, sem uso. Se incomodar, copiar só `Phosphor-Duotone.ttf` para `app/assets/fonts/`, declarar a família no `pubspec.yaml` do app e remover a dependência `phosphor_flutter` (ajustando `fontPackage`/`fontFamily` em `icones.dart`).
- **Checagem visual pendente** (não bloqueante): conferir no navegador/APK, nos temas claro e escuro, que os ícones mostram o preenchimento suave e não só o contorno. Os testes só provam que as duas camadas existem (2 `Icon` por ícone, 91 glifos secundários no font subset).
- O codemod preservou tamanhos/cores dos ícones; ícones que antes eram "outlined" do Material agora são duotone com peso diferente, então alguns podem parecer um pouco maiores/menores que o texto ao lado.

## Threat Flags

Nenhuma superfície nova: mudança visual; nenhuma rota, rede, segredo ou RLS tocado; nenhuma dependência nova (T-qmc-SC aceito; T-qmc-02 mitigado pelo build web release).

## Known Stubs

Nenhum.

## Self-Check: PASSED

- FOUND: app/lib/theme/icones.dart, app/lib/theme/phosphor_icon.dart, app/test/theme/icones_test.dart
- FOUND commits: 7ccb3e1, f5ae569, 1a6d484

## Pós-execução (orquestrador)

- Fonte embutida: `app/assets/fonts/PhosphorDuotone.ttf` + `LICENSE-Phosphor.txt` (MIT, registrada na tela de licenças); `phosphor_flutter` removido do pubspec (o pacote não compila no Flutter 3.47 e trazia seis fontes ao bundle). `Icones` passou a usar `IconData(..., fontFamily: 'PhosphorDuotone')` sem `fontPackage`.
- Trailer Co-Authored-By dos três commits do executor corrigido antes do push.
- Web conferida no navegador (tema escuro): contorno + preenchimento aparecem nas abas, setas, FABs e títulos.
