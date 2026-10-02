import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/auth/presentation/signup_screen.dart';
import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/home/domain/app_routes.dart';
import 'package:meubolso/main.dart';
import 'package:meubolso/router/app_router.dart';

import 'support/fake_wrappers.dart';

// Na web, o link de confirmação do Supabase volta com o resultado no
// fragmento, que o GoRouter lê como rota. Antes isso quebrava com
// "GoException: no routes for location".
void main() {
  testWidgets('link expirado: vai ao login com aviso, sem quebrar',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await tester.pumpWidget(
      wrapWithFakes(fakeAuth: fake, child: const MeuBolsoApp()),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    ).read(appRouterProvider);
    router.go(AppRoutes.signup);
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);

    router.go(
      '/error=access_denied&error_code=otp_expired'
      '&error_description=Email+link+is+invalid+or+has+expired&sb=',
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(avisoLinkInvalido), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
  });

  testWidgets('retorno com token e sessão ativa: vai para a home',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: fake,
        fakeLancamentos: FakeLancamentosRepository(),
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(appRouterProvider);
    router.go('/access_token=abc&expires_in=3600&type=signup');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
  });
}
