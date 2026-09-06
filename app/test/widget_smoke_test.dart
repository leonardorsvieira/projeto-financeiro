import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/home/presentation/home_screen.dart';
import 'package:meubolso/main.dart';

import 'support/fake_auth.dart';

void main() {
  testWidgets('home renders Meu Bolso title and placeholder when logged in',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );

    await tester.pumpWidget(wrapWithFake(fake, const MeuBolsoApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    // AppBar + body title.
    expect(find.text('Meu Bolso'), findsWidgets);
    expect(find.text('Você está logado como'), findsOneWidget);
  });
}