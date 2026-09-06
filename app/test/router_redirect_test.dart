import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/auth/presentation/splash_screen.dart';
import 'package:meubolso/main.dart';

import 'support/fake_wrappers.dart';

void main() {
  testWidgets('sem sessão: rota inicial cai em /login (não /home)',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );

    await tester.pumpWidget(
      wrapWithFakes(fakeAuth: fake, child: const MeuBolsoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('com sessão: rota inicial navega para /home e mostra lista',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeLancamentos = FakeLancamentosRepository();

    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: fake,
        fakeLancamentos: fakeLancamentos,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lançamento ainda'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('deslogar redireciona de /home para /login', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeLancamentos = FakeLancamentosRepository();

    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: fake,
        fakeLancamentos: fakeLancamentos,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum lançamento ainda'), findsOneWidget);

    fake.emit(const AuthState(AuthStatus.unauthenticated));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('MaterialApp tem rota /home bloqueada redirecionando', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );

    await tester.pumpWidget(
      wrapWithFakes(fakeAuth: fake, child: const MeuBolsoApp()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}