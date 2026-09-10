import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/seguranca/application/biometria_providers.dart';

import '../../support/fake_biometria_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setBloqueioAtivo ativa bloqueio se autenticação passar', () async {
    final fakeRepo = FakeBiometriaRepository(authResult: true);
    final container = ProviderContainer(
      overrides: [
        biometriaRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    final ok = await container
        .read(bloqueioBiometricoAtivoProvider.notifier)
        .setBloqueioAtivo(true);

    expect(ok, isTrue);
    expect(fakeRepo.authCalls, equals(1));
    expect(await fakeRepo.isBloqueioAtivo(), isTrue);
  });

  test('setBloqueioAtivo cancela se autenticação falhar', () async {
    final fakeRepo = FakeBiometriaRepository(authResult: false);
    final container = ProviderContainer(
      overrides: [
        biometriaRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    final ok = await container
        .read(bloqueioBiometricoAtivoProvider.notifier)
        .setBloqueioAtivo(true);

    expect(ok, isFalse);
    expect(await fakeRepo.isBloqueioAtivo(), isFalse);
  });
}
