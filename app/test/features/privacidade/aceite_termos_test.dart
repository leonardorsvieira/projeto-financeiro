import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/privacidade/domain/aceite_termos.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/presentation/aceite_termos_screen.dart';
import 'package:meubolso/features/privacidade/presentation/documento_legal_screen.dart';
import 'package:meubolso/main.dart';

import '../../support/fake_wrappers.dart';

void main() {
  group('aceite_termos', () {
    test('metadadosDeAceite carrega versão e data ISO 8601 UTC', () {
      final meta = metadadosDeAceite(agora: DateTime.utc(2026, 10, 1, 12));
      expect(meta, {
        'termos_versao': versaoDocumentos,
        'termos_aceitos_em': '2026-10-01T12:00:00.000Z',
      });
    });

    test('sem `agora`, a data vem em UTC', () {
      final meta = metadadosDeAceite();
      expect(DateTime.parse(meta['termos_aceitos_em']!).isUtc, isTrue);
    });

    test('termosEmDia só aceita a versão vigente', () {
      expect(termosEmDia(versaoDocumentos), isTrue);
      expect(termosEmDia(null), isFalse);
      expect(termosEmDia('2000-01-01'), isFalse);
    });
  });

  group('portão de re-aceite', () {
    /// A tela de teste (800x600) é mais baixa que o conteúdo: rola até o alvo.
    Future<void> tocar(WidgetTester tester, Finder alvo) async {
      await tester.ensureVisible(alvo);
      await tester.pump();
      await tester.tap(alvo);
    }

    Future<FakeAuthRepository> abrir(
      WidgetTester tester, {
      String? termosVersao,
    }) async {
      final fake = FakeAuthRepository(
        AuthState(
          AuthStatus.authenticated,
          email: 'leo@meubolso.com',
          termosVersao: termosVersao,
        ),
        termosEmDia: false,
      );
      await tester.pumpWidget(
        wrapWithFakes(
          fakeAuth: fake,
          fakeLancamentos: FakeLancamentosRepository(),
          child: const MeuBolsoApp(),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('conta sem aceite cai na tela de aceite, não na home', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.byType(AceiteTermosScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('conta com versão antiga também cai na tela de aceite', (
      tester,
    ) async {
      await abrir(tester, termosVersao: '2000-01-01');

      expect(find.byType(AceiteTermosScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Aceitar e continuar grava o aceite e libera a home', (
      tester,
    ) async {
      final fake = await abrir(tester);

      await tocar(
        tester,
        find.widgetWithText(FilledButton, 'Aceitar e continuar'),
      );
      await tester.pumpAndSettle();

      expect(fake.termosAceitos, versaoDocumentos);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AceiteTermosScreen), findsNothing);
    });

    testWidgets('falha ao gravar o aceite mostra erro e mantém o portão', (
      tester,
    ) async {
      final fake = await abrir(tester);
      fake.aceitarTermosErro = Exception('sem rede');

      await tocar(
        tester,
        find.widgetWithText(FilledButton, 'Aceitar e continuar'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não foi possível registrar o aceite. Verifique a conexão e tente '
          'novamente.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AceiteTermosScreen), findsOneWidget);
    });

    testWidgets('Sair desloga e volta ao login', (tester) async {
      final fake = await abrir(tester);

      await tocar(tester, find.widgetWithText(TextButton, 'Sair'));
      await tester.pumpAndSettle();

      expect(fake.signOutChamadas, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('link dos Termos de Uso abre o documento sem redirecionar', (
      tester,
    ) async {
      await abrir(tester);

      final link = find.widgetWithText(TextButton, 'Termos de Uso');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.byType(DocumentoLegalScreen), findsOneWidget);
      expect(find.text('Versão de 04/10/2026'), findsOneWidget);
    });

    testWidgets('link da Política de Privacidade abre o documento', (
      tester,
    ) async {
      await abrir(tester);

      final link = find.widgetWithText(TextButton, 'Política de Privacidade');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.byType(DocumentoLegalScreen), findsOneWidget);
    });
  });
}
