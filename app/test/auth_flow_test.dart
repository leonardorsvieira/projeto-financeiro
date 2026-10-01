import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/auth/presentation/signup_screen.dart';
import 'package:meubolso/features/home/domain/app_routes.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/presentation/documento_legal_screen.dart';
import 'package:meubolso/main.dart';
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

  /// Marca a caixa de aceite dos termos e toca em "Criar conta". O formulário
  /// ficou mais alto que a tela de teste (800x600), então rola até cada alvo.
  Future<void> enviarCadastro(WidgetTester tester) async {
    final caixa = find.byType(Checkbox);
    await tester.ensureVisible(caixa);
    await tester.tap(caixa);
    await tester.pump();
    final criar = find.widgetWithText(FilledButton, 'Criar conta');
    await tester.ensureVisible(criar);
    await tester.tap(criar);
  }

  Future<void> preencherCadastro(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'leo@meubolso.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Senha#12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'Senha#12345');
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
    await enviarCadastro(tester);
    await tester.pump();

    expect(
      find.text('A senha deve ter pelo menos 9 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro: senhas divergentes mostram erro', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpSignup(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'leo@meubolso.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Senha#12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha99999');
    await enviarCadastro(tester);
    await tester.pump();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });

  testWidgets('cadastro: com confirmação de e-mail, avisa para abrir o link',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    )..signUpExigeConfirmacao = true;
    await pumpSignup(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'leo@meubolso.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Senha#12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'Senha#12345');
    await enviarCadastro(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Enviamos um link de confirmação para leo@meubolso.com'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro: sem marcar os termos o botão fica desabilitado',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpSignup(tester, fake);
    await preencherCadastro(tester);

    final criar = find.widgetWithText(FilledButton, 'Criar conta');
    await tester.ensureVisible(criar);
    expect(tester.widget<FilledButton>(criar).onPressed, isNull);
    expect(fake.ultimoSignUpMetadados, isNull);

    final caixa = find.byType(Checkbox);
    await tester.ensureVisible(caixa);
    await tester.tap(caixa);
    await tester.pump();

    expect(tester.widget<FilledButton>(criar).onPressed, isNotNull);
  });

  testWidgets('cadastro: envia a versão e a data do aceite nos metadados',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await pumpSignup(tester, fake);
    await preencherCadastro(tester);

    await enviarCadastro(tester);
    await tester.pumpAndSettle();

    final meta = fake.ultimoSignUpMetadados;
    expect(meta, isNotNull);
    expect(meta!['termos_versao'], versaoDocumentos);
    final quando = DateTime.parse(meta['termos_aceitos_em'] as String);
    expect(quando.isUtc, isTrue);
  });

  testWidgets('cadastro: os links abrem Termos e Política sem perder o form',
      (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await tester.pumpWidget(
      wrapWithFake(fake, const MeuBolsoApp()),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(LoginScreen))).go(
      AppRoutes.signup,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'leo@meubolso.com',
    );

    final termos = find.widgetWithText(TextButton, 'Termos de Uso');
    await tester.ensureVisible(termos);
    await tester.tap(termos);
    await tester.pumpAndSettle();
    expect(find.byType(DocumentoLegalScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('leo@meubolso.com'), findsOneWidget);
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