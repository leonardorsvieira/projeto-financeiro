import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../lancamentos/application/notificacoes_service.dart';
import '../domain/cartao_credito.dart';

class CartoesNotificacoesService {
  CartoesNotificacoesService._();

  /// Agenda ou notifica o usuário sobre o vencimento de faturas e validade dos cartões.
  static Future<void> agendarNotificacoesCartoes(List<CartaoCredito> cartoes) async {
    if (kIsWeb) return;
    final notificacoesService = NotificacoesService.instance;
    await notificacoesService.init();

    final plugin = FlutterLocalNotificationsPlugin();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cartoes_lembretes',
        'Lembretes de Cartão',
        channelDescription: 'Avisa sobre faturas a vencer e validade dos cartões',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final now = DateTime.now();
    for (final cartao in cartoes) {
      // 1. Notificação de Validade do Cartão (se informada)
      if (cartao.validadeMMYY != null && cartao.validadeMMYY!.contains('/')) {
        try {
          final parts = cartao.validadeMMYY!.split('/');
          final mesValidade = int.parse(parts[0]);
          final anoValidade = int.parse('20${parts[1]}');

          if (now.year == anoValidade && now.month == mesValidade) {
            await plugin.show(
              id: (cartao.id.hashCode + 900).abs() % 100000,
              title: '⚠️ Validade do Cartão ${cartao.nome}',
              body: 'Seu cartão ${cartao.nome} expira este mês (${cartao.validadeMMYY}). Verifique a 2ª via enviada pelo banco.',
              notificationDetails: details,
            );
          }
        } catch (_) {}
      }

      // 2. Notificação de Vencimento da Fatura (próximo diaVencimento)
      try {
        var proxVencimento = DateTime(now.year, now.month, cartao.diaVencimento);
        if (proxVencimento.isBefore(DateTime(now.year, now.month, now.day))) {
          proxVencimento = DateTime(now.year, now.month + 1, cartao.diaVencimento);
        }

        final diasRestantes = proxVencimento.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (diasRestantes <= 3 && diasRestantes >= 0) {
          final textoDias = diasRestantes == 0 ? 'vence HOJE' : 'vence em $diasRestantes dia(s)';
          await plugin.show(
            id: (cartao.id.hashCode + 100).abs() % 100000,
            title: '💳 Fatura ${cartao.nome}',
            body: 'A fatura do seu cartão ${cartao.nome} (dia ${cartao.diaVencimento}) $textoDias. Lembre-se de realizar o pagamento!',
            notificationDetails: details,
          );
        }
      } catch (_) {}
    }
  }
}
