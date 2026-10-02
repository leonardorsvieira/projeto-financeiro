import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meubolso/features/acesso/application/acesso_providers.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/cartoes/application/cartoes_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';

import 'fake_acesso_repository.dart';
import 'fake_auth.dart';
import 'fake_cartoes_repository.dart';
import 'fake_lancamentos_repository.dart';

export 'fake_acesso_repository.dart';
export 'fake_auth.dart';
export 'fake_cartoes_repository.dart';
export 'fake_lancamentos_repository.dart';

ProviderScope wrapWithFakes({
  required FakeAuthRepository fakeAuth,
  FakeLancamentosRepository? fakeLancamentos,
  FakeAcessoRepository? fakeAcesso,
  FakeCartoesRepository? fakeCartoes,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      // Padrão: conta ativa, então o portão de acesso não interfere.
      acessoRepositoryProvider.overrideWithValue(
        fakeAcesso ?? FakeAcessoRepository(),
      ),
      // Padrão: sem cartões e pergunta já respondida (sem diálogo).
      cartoesRepositoryProvider.overrideWithValue(
        fakeCartoes ?? FakeCartoesRepository(),
      ),
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
