import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/auth/presentation/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'support/fake_auth.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, FakeAuthRepository fake,
      [Widget? child]) async {
    await tester.pumpWidget(
      wrapWithFake(fake, MaterialApp(home: child ?? const LoginScreen())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSignup(WidgetTester tester, FakeAuthRepository fake) async {
    await tester.pumpWidget(
      wrapWithFake(fake, const MaterialApp(home: SignupScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login: e-mail inválido não submete e mostra erro', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpLogin(tester, fake);

    await tester.enterText(find.byType(TextFormField).first, 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('E-mail inválido.'), findsOneWidget);
  });

  testWidgets('cadastro: senha curta mostra erro', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpSignup(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'leo@meubolso.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro: senhas divergentes mostram erro', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpSignup(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'leo@meubolso.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha99999');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });

  testWidgets('login: credenciais inválidas exibem mensagem amigável',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    fake.signInError = AuthException('Invalid login credentials');
    await pumpLogin(tester, fake);

    await tester.enterText(
      find.byType(TextFormField).first,
      'leo@meubolso.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'errada123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });
}