import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'widget_agenda.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String _androidProvider = 'MeuBolsoWidgetProvider';

  static const String _chaveSaldo = 'widget_saldo';
  static const String _chaveQtd = 'widget_venc_qtd';
  static const String _chaveLegada = 'widget_vencimentos';

  static String _chaveVenc(int i, String campo) => 'widget_venc_${i}_$campo';

  /// Todas as chaves gravadas no widget; `limpar()` zera cada uma delas.
  static List<String> get chaves => [
    _chaveSaldo,
    _chaveQtd,
    _chaveLegada,
    for (var i = 1; i <= maxLinhasAgendaWidget; i++)
      for (final c in const ['data', 'nome', 'valor']) _chaveVenc(i, c),
  ];

  /// Remove saldo e vencimentos do widget (usado ao sair da conta).
  static Future<void> limpar() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      for (final k in chaves) {
        await HomeWidget.saveWidgetData<String>(k, null);
      }
      await _atualizar();
    } catch (e) {
      debugPrint('HomeWidgetService.limpar erro: $e');
    }
  }

  /// Atualiza saldo e até 3 vencimentos no Widget da tela inicial (Android).
  static Future<void> atualizarWidget({
    required String saldoFormatado,
    required List<LinhaAgendaWidget> vencimentos,
  }) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await HomeWidget.saveWidgetData<String>(_chaveSaldo, saldoFormatado);
      await HomeWidget.saveWidgetData<String>(_chaveLegada, null);
      await HomeWidget.saveWidgetData<String>(
        _chaveQtd,
        '${vencimentos.length.clamp(0, maxLinhasAgendaWidget)}',
      );
      for (var i = 1; i <= maxLinhasAgendaWidget; i++) {
        final l = i <= vencimentos.length ? vencimentos[i - 1] : null;
        await HomeWidget.saveWidgetData<String>(_chaveVenc(i, 'data'), l?.data);
        await HomeWidget.saveWidgetData<String>(_chaveVenc(i, 'nome'), l?.nome);
        await HomeWidget.saveWidgetData<String>(
          _chaveVenc(i, 'valor'),
          l?.valor,
        );
      }
      await _atualizar();
    } catch (e) {
      debugPrint('HomeWidgetService.atualizarWidget erro: $e');
    }
  }

  static Future<void> _atualizar() => HomeWidget.updateWidget(
    name: _androidProvider,
    androidName: _androidProvider,
  );
}
