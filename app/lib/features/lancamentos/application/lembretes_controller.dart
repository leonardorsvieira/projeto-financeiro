import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lancamento.dart';
import 'lancamentos_providers.dart';
import 'notificacoes_service.dart';
import 'preferencias_service.dart';

/// Observa a lista de lançamentos e mantém as notificações de vencimento
/// sincronizadas (cancela as antigas e reagenda conforme o estado atual).
/// Só deve ser inicializado em plataformas mobile (Android/iOS).
class LembretesController extends AsyncNotifier<void> {
  PreferenciasLembretes? _prefsAtuais;

  @override
  Future<void> build() async {
    // Web não suporta notificação agendada — não faz nada.
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await NotificacoesService.instance.init();

    final prefs = await ref.watch(preferenciasLembretesProvider.future);
    _prefsAtuais = prefs;

    ref.listen(lancamentosStreamProvider, (_, next) {
      next.whenData((lancamentos) => _sincronizar(lancamentos));
    });

    // Agenda para o estado atual na primeira carga.
    ref.read(lancamentosStreamProvider).whenData(_sincronizar);

    ref.onDispose(() {});
  }

  Future<void> _sincronizar(List<Lancamento> lancamentos) async {
    final prefs = _prefsAtuais;
    if (prefs == null) return;
    await NotificacoesService.instance.cancelarTudo();
    for (final lan in lancamentos) {
      await NotificacoesService.instance.agendarLembrete(
        lan,
        hora: prefs.hora,
        minuto: prefs.minuto,
        diasAntes: prefs.diasAntes,
      );
    }
  }

  /// Altera preferências (horário + dias antes). Persiste e reagenda.
  Future<void> alterarPreferencias(PreferenciasLembretes prefs) async {
    _prefsAtuais = prefs;
    await ref
        .read(preferenciasServiceProviderProvider)
        .salvarLembretes(prefs);
    ref.invalidate(preferenciasLembretesProvider);
    final lancamentos = ref.read(lancamentosStreamProvider).value;
    if (lancamentos != null) await _sincronizar(lancamentos);
  }
}

final lembretesControllerProvider =
    AsyncNotifierProvider<LembretesController, void>(LembretesController.new);