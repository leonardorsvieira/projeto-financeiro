import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/theme/app_theme.dart';
import 'package:meubolso/theme/glass.dart';

Widget _app(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: b),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('GlassBackground renderiza filho e gradiente', (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(
        _app(const GlassBackground(child: Text('oi')), b: b),
      );
      expect(find.text('oi'), findsOneWidget);
      final boxes = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((d) =>
              d.decoration is BoxDecoration &&
              (d.decoration as BoxDecoration).gradient is LinearGradient);
      expect(boxes, isNotEmpty);
    }
  });

  testWidgets('GlassTokens difere entre claro e escuro', (tester) async {
    late GlassTokens claro;
    late GlassTokens escuro;
    await tester.pumpWidget(_app(Builder(builder: (c) {
      claro = GlassTokens.of(c);
      return const SizedBox();
    })));
    await tester.pumpWidget(_app(Builder(builder: (c) {
      escuro = GlassTokens.of(c);
      return const SizedBox();
    }), b: Brightness.dark));
    await tester.pumpAndSettle();
    expect(claro.fill.computeLuminance(), greaterThan(0.8));
    expect(escuro.fill.computeLuminance(), lessThan(0.2));
  });

  testWidgets('GlassSurface usa BackdropFilter só com blur', (tester) async {
    await tester.pumpWidget(
      _app(const GlassSurface(blur: true, child: Text('a'))),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);
    await tester.pumpWidget(_app(const GlassSurface(child: Text('a'))));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('GlassCard mantém Card e filho', (tester) async {
    await tester.pumpWidget(_app(const GlassCard(child: Text('x'))));
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('GlassPageTransitionsBuilder envolve rota em GlassBackground',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: GlassPageTransitionsBuilder(
            base: ZoomPageTransitionsBuilder(),
          ),
        }),
      ),
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('pagina2')),
            )),
            child: const Text('ir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(GlassBackground),
        matching: find.text('pagina2'),
      ),
      findsOneWidget,
    );
  });

  test('AppTheme está ligado ao vidro', () {
    expect(AppTheme.light.scaffoldBackgroundColor, Colors.transparent);
    expect(AppTheme.dark.cardTheme.color!.a, lessThan(1));
    expect(
      AppTheme.light.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<GlassPageTransitionsBuilder>(),
    );
  });
}
