import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String _androidProvider = 'MeuBolsoWidgetProvider';

  /// Remove o saldo e os vencimentos do widget (usado ao sair da conta).
  static Future<void> limpar() =>
      atualizarWidget(saldoFormatado: '—', vencimentosTexto: '');

  /// Atualiza as informações exibidas no Widget da tela inicial do Android.
  static Future<void> atualizarWidget({
    required String saldoFormatado,
    required String vencimentosTexto,
  }) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await HomeWidget.saveWidgetData<String>('widget_saldo', saldoFormatado);
      await HomeWidget.saveWidgetData<String>(
        'widget_vencimentos',
        vencimentosTexto,
      );

      await HomeWidget.updateWidget(
        name: _androidProvider,
        androidName: _androidProvider,
      );
    } catch (e) {
      debugPrint('HomeWidgetService.atualizarWidget erro: $e');
    }
  }
}
