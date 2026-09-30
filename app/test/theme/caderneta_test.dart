import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/theme/caderneta.dart';

void main() {
  test('tokens claros da Caderneta', () {
    final c = CadernetaCores.de(Brightness.light);
    expect(c.papel, const Color(0xFFF4ECD8));
    expect(c.tinta, const Color(0xFF1D2A47));
    expect(c.margem, const Color(0xFFB3261E));
    expect(c.receita, const Color(0xFF2D6A3E));
  });

  test('caderneta noturna: papel navy, tinta creme', () {
    final c = CadernetaCores.de(Brightness.dark);
    expect(c.papel.computeLuminance(), lessThan(0.1));
    expect(c.tinta.computeLuminance(), greaterThan(0.7));
  });

  test('paleta de categorias', () {
    final p = Caderneta.paletaCategorias(Brightness.light);
    expect(p.length, greaterThanOrEqualTo(9));
    expect(p.toSet().length, p.length);
    expect(p.take(5).toList(), const [
      Color(0xFF1D2A47),
      Color(0xFFB3261E),
      Color(0xFF2D6A3E),
      Color(0xFF8A6D2F),
      Color(0xFF5C5C7A),
    ]);
  });

  test('estilos de texto', () {
    expect(CadernetaTexto.numero(size: 16).fontFamily, 'IBMPlexMono');
    final d = CadernetaTexto.display(size: 20);
    expect(d.fontFamily, 'Fraunces');
    expect(d.fontVariations, contains(const FontVariation.weight(600)));
  });

  testWidgets('PapelPautado renderiza filho e pauta', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PapelPautado(child: Text('saldo'))),
      ),
    );
    expect(find.text('saldo'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(MargemVermelha), findsOneWidget);
  });

  testWidgets('CarimboLogo desenha o carimbo no tamanho pedido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CarimboLogo(tamanho: 40))),
    );
    final box = tester.renderObject<RenderBox>(
      find.descendant(
        of: find.byType(CarimboLogo),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(box.size, const Size.square(40));
    expect(find.bySemanticsLabel('Meu Bolso'), findsOneWidget);
  });
}
