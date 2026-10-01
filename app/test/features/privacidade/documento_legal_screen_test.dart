import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/domain/textos_legais.dart';
import 'package:meubolso/features/privacidade/presentation/documento_legal_screen.dart';

void main() {
  testWidgets('mostra título, versão e e-mail de contato', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentoLegalScreen(documento: politicaDePrivacidade),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(politicaDePrivacidade.titulo), findsWidgets);
    expect(find.text('Versão de 01/10/2026'), findsOneWidget);
    expect(find.textContaining(emailPrivacidade), findsWidgets);
  });

  testWidgets('título de seção em Fraunces e parágrafo em Inter',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentoLegalScreen(documento: politicaDePrivacidade),
      ),
    );
    await tester.pumpAndSettle();

    final primeira = politicaDePrivacidade.secoes.first;
    final titulo = tester.widget<Text>(find.text(primeira.titulo));
    expect(titulo.style?.fontFamily, 'Fraunces');

    final paragrafo = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.style?.fontFamily == 'Inter' &&
            (w.data ?? '').isNotEmpty,
      ).first,
    );
    expect(paragrafo.style?.fontFamily, 'Inter');
  });

  testWidgets('abre os Termos de Uso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentoLegalScreen(documento: termosDeUso)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Termos de Uso'), findsWidgets);
    expect(find.text('Versão de 01/10/2026'), findsOneWidget);
  });
}
