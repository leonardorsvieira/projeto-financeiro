import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/application/home_widget_service.dart';

/// Apaga tudo que o app guarda no aparelho sobre o usuário que saiu:
/// preferências locais (cartões, contas do Open Finance, lembretes, biometria),
/// notificações agendadas (têm descrição e valor dos lançamentos) e o widget
/// da tela inicial (mostra o saldo). Chamado quando a sessão termina.
Future<void> limparDadosLocais() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } on Object catch (e) {
    debugPrint('limparDadosLocais: preferências: $e');
  }

  if (kIsWeb) return;

  try {
    await FlutterLocalNotificationsPlugin().cancelAll();
  } on Object catch (e) {
    debugPrint('limparDadosLocais: notificações: $e');
  }
  await HomeWidgetService.limpar();
}

/// [limparDadosLocais] como provider, para as telas chamarem pelo `ref` e os
/// testes trocarem por um fake (sem plugins de notificação/widget).
final limparDadosLocaisProvider = Provider<Future<void> Function()>(
  (ref) => limparDadosLocais,
);
