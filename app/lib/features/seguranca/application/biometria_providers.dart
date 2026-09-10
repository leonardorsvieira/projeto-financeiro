import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometria_service.dart';

final biometriaRepositoryProvider = Provider<BiometriaRepository>((ref) {
  return BiometriaService();
});

final bloqueioBiometricoAtivoProvider =
    AsyncNotifierProvider<BloqueioBiometricoNotifier, bool>(
  BloqueioBiometricoNotifier.new,
);

class BloqueioBiometricoNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(biometriaRepositoryProvider);
    return await repo.isBloqueioAtivo();
  }

  Future<bool> setBloqueioAtivo(bool enabled) async {
    final repo = ref.read(biometriaRepositoryProvider);
    if (enabled) {
      final autenticado = await repo.autenticar(
        motivo: 'Confirme sua digital para ativar o bloqueio do app',
      );
      if (!autenticado) return false;
    }
    await repo.setBloqueioAtivo(enabled);
    state = AsyncData(enabled);
    return true;
  }
}
