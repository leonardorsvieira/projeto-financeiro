import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/acesso/application/acesso_providers.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/presentation/aviso_vencimento_acesso.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../support/fake_acesso_repository.dart';
import '../../support/fake_auth.dart';

void main() {
  final hoje = DateTime(2026, 10, 1, 15, 30);

  Future<void> abrir(WidgetTester tester, StatusAcesso status) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              const AuthState(
                AuthStatus.authenticated,
                email: 'leo@meubolso.com',
              ),
            ),
          ),
          acessoRepositoryProvider.overrideWithValue(
            FakeAcessoRepository(statusAtual: status),
          ),
          acessoRelogioProvider.overrideWithValue(() => hoje),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AvisoVencimentoAcesso()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('vence em 3 dias: mostra o aviso com a data', (tester) async {
    await abrir(
      tester,
      StatusAcesso(ativo: true, admin: false, validoAte: DateTime(2026, 10, 4)),
    );

    expect(find.text('Seu acesso vence em 3 dias (04/10).'), findsOneWidget);
    expect(find.text('Renovar'), findsOneWidget);
  });

  testWidgets('vence hoje', (tester) async {
    await abrir(
      tester,
      StatusAcesso(ativo: true, admin: false, validoAte: DateTime(2026, 10, 1)),
    );

    expect(find.text('Seu acesso vence hoje.'), findsOneWidget);
  });

  testWidgets('ainda longe do vencimento: sem aviso', (tester) async {
    await abrir(
      tester,
      StatusAcesso(
        ativo: true,
        admin: false,
        validoAte: DateTime(2026, 10, 20),
      ),
    );

    expect(find.textContaining('Seu acesso vence'), findsNothing);
  });

  testWidgets('sem prazo: sem aviso', (tester) async {
    await abrir(tester, const StatusAcesso(ativo: true, admin: false));

    expect(find.textContaining('Seu acesso vence'), findsNothing);
  });

  testWidgets('administrador: sem aviso', (tester) async {
    await abrir(
      tester,
      StatusAcesso(ativo: true, admin: true, validoAte: DateTime(2026, 10, 4)),
    );

    expect(find.textContaining('Seu acesso vence'), findsNothing);
  });
}
