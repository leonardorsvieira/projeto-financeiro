import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/lancamentos/presentation/lancamentos_list_screen.dart';
import 'package:meubolso/main.dart';

import 'support/fake_wrappers.dart';

void main() {
  testWidgets('home mostra a lista de lançamentos (empty state) logado',
      (tester) async {
    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: FakeAuthRepository(
          const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
        ),
        fakeLancamentos: FakeLancamentosRepository(),
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LancamentosListScreen), findsOneWidget);
    expect(find.text('Nenhum lançamento ainda'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}