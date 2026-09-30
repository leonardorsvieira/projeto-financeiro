import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/theme/app_theme.dart';
import 'package:meubolso/theme/icones.dart';

void main() {
  group('Icones', () {
    final fonte = File('lib/theme/icones.dart').readAsStringSync();
    final papeis = RegExp(
      r'static const (\w+) = IconData\(\s*(0x[0-9a-fA-F]+),\s*'
      r'fontFamily: _f,\s*fontPackage: _p,?\s*\);',
    ).allMatches(fonte).toList();

    test('há um papel por ícone e todos usam a fonte PhosphorDuotone', () {
      expect(papeis.length, greaterThanOrEqualTo(80));
      expect(fonte, contains("static const String _f = 'PhosphorDuotone';"));
      expect(fonte, contains("static const String _p = 'phosphor_flutter';"));
      // Nenhuma constante de ícone fora do padrão (p. ex. `Icons.x` ou outra
      // família): toda `static const` de papel casou com a regex acima.
      final declaracoes = RegExp(r'static const (?!String|Map)\w+ =')
          .allMatches(fonte)
          .length;
      expect(papeis.length, declaracoes);
    });

    test('papéis principais usam a família duotone do pacote', () {
      for (final i in [Icones.ditar, Icones.resumo, Icones.voltar]) {
        expect(i.fontFamily, 'PhosphorDuotone');
        expect(i.fontPackage, 'phosphor_flutter');
      }
    });

    test('todo papel tem a camada de preenchimento (glifo secundário)', () {
      for (final m in papeis) {
        final codigo = int.parse(m.group(2)!);
        // Só em teste (fora do bundle): o codePoint vem do texto do arquivo.
        final contorno = IconData(
          // ignore: non_const_argument_for_const_parameter
          codigo,
          fontFamily: 'PhosphorDuotone',
          fontPackage: 'phosphor_flutter',
        );
        final preenchimento = Icones.preenchimentoDe(contorno);
        expect(preenchimento, isNotNull, reason: m.group(1));
        expect(preenchimento!.codePoint, isNot(codigo), reason: m.group(1));
      }
    });

    test('ícone que não é Phosphor não tem preenchimento', () {
      expect(Icones.preenchimentoDe(Icons.add), isNull);
    });

    testWidgets('PhosphorIcon pinta duas camadas (contorno + preenchimento)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PhosphorIcon(Icones.ditar),
        ),
      );
      expect(find.byWidgetPredicate((w) => w is Icon), findsNWidgets(2));
      expect(find.byIcon(Icones.ditar), findsOneWidget);
    });
  });

  group('AppTheme', () {
    for (final (nome, tema) in [
      ('claro', AppTheme.light),
      ('escuro', AppTheme.dark),
    ]) {
      testWidgets('voltar e fechar da AppBar são Phosphor ($nome)', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: Scaffold(
              appBar: AppBar(
                leading: const BackButton(),
                actions: const [CloseButton()],
              ),
            ),
          ),
        );
        expect(find.byIcon(Icones.voltar), findsOneWidget);
        expect(find.byIcon(Icones.fechar), findsOneWidget);
      });
    }

    testWidgets('SegmentedButton selecionado mostra o check Phosphor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Um')),
                ButtonSegment(value: 2, label: Text('Dois')),
              ],
              selected: const {1},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icones.confirmar), findsOneWidget);
    });
  });
}
