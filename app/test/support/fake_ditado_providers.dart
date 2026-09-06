import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/ditado/application/ditado_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';

import 'fake_audio_recorder_service.dart';
import 'fake_auth.dart';
import 'fake_ditado_repository.dart';
import 'fake_lancamentos_repository.dart';

ProviderScope wrapWithDitadoFakes({
  required FakeAuthRepository fakeAuth,
  FakeLancamentosRepository? fakeLancamentos,
  FakeAudioRecorderService? fakeAudio,
  FakeDitadoRepository? fakeDitado,
  DateTime Function()? relogio,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      if (fakeLancamentos != null)
        lancamentosRepositoryProvider.overrideWithValue(fakeLancamentos),
      if (fakeAudio != null)
        audioRecorderServiceProvider.overrideWithValue(fakeAudio),
      if (fakeDitado != null)
        ditadoRepositoryProvider.overrideWithValue(fakeDitado),
      if (relogio != null)
        ditadoRelogioProvider.overrideWithValue(relogio),
    ],
    child: child,
  );
}

class FakeRelogio {
  FakeRelogio([DateTime? inicio])
      : agora = inicio ?? DateTime(2026, 1, 1);

  DateTime agora;

  DateTime call() => agora;

  void avancar(Duration duracao) => agora = agora.add(duracao);
}