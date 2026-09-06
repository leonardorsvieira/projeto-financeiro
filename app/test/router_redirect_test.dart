import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/auth/presentation/splash_screen.dart';
import 'package:meubolso/main.dart';

import 'support/fake_auth.dart';

void main() {
  testWidgets('sem sessão: rota inicial cai em /login (não /home)',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );

    await tester.pumpWidget(wrapWithFake(fake, const MeuBolsoApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('com sessão: rota inicial navega para /home', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );

    await tester.pumpWidget(wrapWithFake(fake, const MeuBolsoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Você está logado como'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('deslogar redireciona de /home para /login', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );

    await tester.pumpWidget(wrapWithFake(fake, const MeuBolsoApp()));
    await tester.pumpAndSettle();
    expect(find.text('Você está logado como'), findsOneWidget);

    fake.emit(const AuthState(AuthStatus.unauthenticated));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('MaterialApp tem rota /home bloqueada redirecionando', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );

    await tester.pumpWidget(wrapWithFake(fake, const MeuBolsoApp()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}