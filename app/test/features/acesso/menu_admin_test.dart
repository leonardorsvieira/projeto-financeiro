import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/presentation/admin_acessos_screen.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/home/domain/app_routes.dart';
import 'package:meubolso/main.dart';

import '../../support/fake_wrappers.dart';

void main() {
  Future<void> abrir(WidgetTester tester, StatusAcesso status) async {
    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: FakeAuthRepository(
          const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
        ),
        fakeLancamentos: FakeLancamentosRepository(),
        fakeAcesso: FakeAcessoRepository(statusAtual: status),
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Opções'));
    await tester.pumpAndSettle();
  }

  testWidgets('administrador vê "Clientes e acessos" e abre a tela', (
    tester,
  ) async {
    await abrir(tester, const StatusAcesso(ativo: true, admin: true));

    await abrirMenu(tester);
    expect(find.text('Clientes e acessos'), findsOneWidget);

    await tester.tap(find.text('Clientes e acessos'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminAcessosScreen), findsOneWidget);
  });

  testWidgets('quem não é administrador não vê o item', (tester) async {
    await abrir(tester, const StatusAcesso(ativo: true, admin: false));

    await abrirMenu(tester);

    expect(find.text('Clientes e acessos'), findsNothing);
  });

  testWidgets('quem não é administrador volta à home se abrir a rota', (
    tester,
  ) async {
    await abrir(tester, const StatusAcesso(ativo: true, admin: false));

    final contexto = tester.element(find.byType(HomeScreen));
    GoRouter.of(contexto).go(AppRoutes.adminAcessos);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AdminAcessosScreen), findsNothing);
  });
}
