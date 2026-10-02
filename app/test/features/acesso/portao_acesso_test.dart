import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/presentation/sem_acesso_screen.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/home/domain/app_routes.dart';
import 'package:meubolso/features/privacidade/presentation/privacidade_dados_screen.dart';
import 'package:meubolso/main.dart';

import '../../support/fake_wrappers.dart';

void main() {
  const inativo = StatusAcesso(ativo: false, admin: false);

  /// A tela de teste (800x600) é mais baixa que o conteúdo: rola até o alvo.
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
  }

  Future<FakeAuthRepository> abrir(
    WidgetTester tester,
    FakeAcessoRepository acesso,
  ) async {
    final auth = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: auth,
        fakeLancamentos: FakeLancamentosRepository(),
        fakeAcesso: acesso,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  group('portão de acesso', () {
    testWidgets('conta vencida cai em "Seu acesso não está ativo"', (
      tester,
    ) async {
      await abrir(
        tester,
        FakeAcessoRepository(
          statusAtual: StatusAcesso(
            ativo: false,
            admin: false,
            validoAte: DateTime(2026, 9, 30),
          ),
        ),
      );

      expect(find.byType(SemAcessoScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Seu acesso não está ativo'), findsOneWidget);
      expect(find.text('Sua assinatura venceu em 30/09/2026.'), findsOneWidget);
    });

    testWidgets('conta sem linha em acessos não mostra a frase de vencimento', (
      tester,
    ) async {
      await abrir(tester, FakeAcessoRepository(statusAtual: inativo));

      expect(find.byType(SemAcessoScreen), findsOneWidget);
      expect(find.textContaining('venceu'), findsNothing);
    });

    testWidgets('Meus dados continua acessível e não volta para o aviso', (
      tester,
    ) async {
      await abrir(tester, FakeAcessoRepository(statusAtual: inativo));

      await tocar(tester, find.text('Meus dados'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacidadeDadosScreen), findsOneWidget);
      expect(find.byType(SemAcessoScreen), findsNothing);
    });

    testWidgets('outra rota por URL volta para o aviso', (tester) async {
      await abrir(tester, FakeAcessoRepository(statusAtual: inativo));

      final contexto = tester.element(find.byType(SemAcessoScreen));
      GoRouter.of(contexto).go(AppRoutes.metas);
      await tester.pumpAndSettle();

      expect(find.byType(SemAcessoScreen), findsOneWidget);
    });

    testWidgets('administrador passa direto pelo portão', (tester) async {
      await abrir(
        tester,
        FakeAcessoRepository(
          statusAtual: const StatusAcesso(ativo: false, admin: true),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SemAcessoScreen), findsNothing);
    });

    testWidgets('erro na primeira consulta não trava a conta (falha aberta)', (
      tester,
    ) async {
      final acesso = FakeAcessoRepository(statusAtual: inativo)
        ..erroStatus = Exception('sem rede');
      await abrir(tester, acesso);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SemAcessoScreen), findsNothing);
    });

    testWidgets('"Já renovei" consulta de novo e libera o app', (tester) async {
      final acesso = FakeAcessoRepository(statusAtual: inativo);
      await abrir(tester, acesso);
      expect(find.byType(SemAcessoScreen), findsOneWidget);

      acesso.statusAtual = const StatusAcesso(ativo: true, admin: false);
      await tocar(tester, find.text('Já renovei — verificar de novo'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SemAcessoScreen), findsNothing);
      expect(acesso.statusChamadas, 2);
    });

    testWidgets(
      '"Já renovei" com a conta ainda inativa avisa e mantém o portão',
      (tester) async {
        await abrir(tester, FakeAcessoRepository(statusAtual: inativo));

        await tocar(tester, find.text('Já renovei — verificar de novo'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Seu acesso ainda não está ativo. Se você já pagou, aguarde a '
            'liberação do vendedor.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SemAcessoScreen), findsOneWidget);
      },
    );

    testWidgets('Sair desloga e volta ao login', (tester) async {
      final auth = await abrir(
        tester,
        FakeAcessoRepository(statusAtual: inativo),
      );

      await tocar(tester, find.widgetWithText(TextButton, 'Sair'));
      await tester.pumpAndSettle();

      expect(auth.signOutChamadas, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
