import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';

import 'fake_auth.dart';
import 'fake_lancamentos_repository.dart';

export 'fake_auth.dart';
export 'fake_lancamentos_repository.dart';

ProviderScope wrapWithFakes({
  required FakeAuthRepository fakeAuth,
  FakeLancamentosRepository? fakeLancamentos,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      if (fakeLancamentos != null)
        lancamentosRepositoryProvider.overrideWithValue(fakeLancamentos),
    ],
    child: child,
  );
}

// Mantém compatibilidade com testes que só precisam do auth fake.
ProviderScope wrapWithFake(FakeAuthRepository fake, Widget child) {
  return wrapWithFakes(fakeAuth: fake, child: child);
}