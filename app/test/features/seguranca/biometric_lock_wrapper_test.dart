import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/seguranca/application/biometria_providers.dart';
import 'package:meubolso/features/seguranca/presentation/biometric_lock_wrapper.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../support/fake_biometria_repository.dart';

void main() {
  testWidgets('exibe child diretamente quando bloqueio desativado', (tester) async {
    final fakeRepo = FakeBiometriaRepository(ativoInicial: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometriaRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BiometricLockWrapper(
            child: Text('Conteúdo do App'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conteúdo do App'), findsOneWidget);
    expect(find.text('Meu Bolso Bloqueado'), findsNothing);
  });

  testWidgets('exibe tela de bloqueio quando biometria ativa e falhar', (tester) async {
    final fakeRepo = FakeBiometriaRepository(ativoInicial: true, authResult: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometriaRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BiometricLockWrapper(
            child: Text('Conteúdo Protegido'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meu Bolso Bloqueado'), findsOneWidget);
    expect(find.text('Conteúdo Protegido'), findsNothing);
  });
}
