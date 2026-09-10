import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/lancamento.dart';

/// Instante de disparo agendado (T-X ou T-0).
@visibleForTesting
typedef AgendaNotificacao = ({tz.TZDateTime quando, String tipo, String titulo});

/// Serviço de notificações locais para lembretes de vencimento.
/// Agenda 2 notificações por lançamento: X dias antes e no próprio dia,
/// no horário configurável (padrão 09:00).
class NotificacoesService {
  NotificacoesService._();

  static final NotificacoesService instance = NotificacoesService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _canalLembretes = 0;
  static const String _canalId = 'lembretes_vencimento';
  static const String _canalNome = 'Lembretes de vencimento';

  bool _inicializado = false;

  bool get inicializado => _inicializado;

  /// Inicializa o plugin, o timezone e (se válido) pede permissão.
  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      String tzName;
      try {
        tzName = (await FlutterTimezone.getLocalTimezone()).identifier;
      } catch (_) {
        tzName = await _tzFallback();
      }
      tz.setLocalLocation(tz.getLocation(tzName));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(settings: settings);
      _inicializado = true;
    } catch (e) {
      debugPrint('NotificacoesService.init erro: $e');
    }
  }

  Future<String> _tzFallback() async {
    return 'America/Sao_Paulo';
  }

  /// Pede permissão de notificação (Android 13+ / iOS). Retorna true se concedida.
  Future<bool> pedirPermissao() async {
    if (!_inicializado) await init();
    try {
      final ehAndroid = defaultTargetPlatform == TargetPlatform.android;
      final ehApple = defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      if (ehAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android == null) return true;
        final concedida = await android.requestNotificationsPermission();
        return concedida ?? true;
      }
      if (ehApple) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios == null) return true;
        final concedida = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return concedida ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('NotificacoesService.pedirPermissao erro: $e');
      return false;
    }
  }

  /// Verifica se notificações estão habilitadas no sistema.
  Future<bool> estaoHabilitadas() async {
    if (!_inicializado) await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Agenda os lembretes de um lançamento com vencimento futuro.
  /// Retorna false (com mensagem) se falhar.
  Future<bool> agendarLembrete(
    Lancamento lancamento, {
    required int hora,
    required int minuto,
    required int diasAntes,
  }) async {
    final venc = lancamento.vencimento;
    if (venc == null || _vencimentoExpirado(venc)) return true;

    try {
      for (final item in datasDeAgendamento(venc, hora, minuto, diasAntes)) {
        await _agendar(
          id: _idNotificacao(lancamento.id, item.tipo),
          titulo: item.titulo,
          corpo: _corpo(lancamento),
          quando: item.quando,
        );
      }
      return true;
    } catch (e) {
      debugPrint('NotificacoesService.agendarLembrete erro: $e');
      return false;
    }
  }

  /// Instante de disparo agendado (T-X ou T-0).
  /// [diasAntes] = 0 agenda apenas no dia do vencimento.
  @visibleForTesting
  List<AgendaNotificacao> datasDeAgendamento(
    DateTime venc,
    int hora,
    int minuto,
    int diasAntes,
  ) {
    final tx = tz.TZDateTime(
      tz.local,
      venc.year,
      venc.month,
      venc.day - diasAntes,
      hora,
      minuto,
    );
    final diaDoVencimento = tz.TZDateTime(
      tz.local,
      venc.year,
      venc.month,
      venc.day,
      hora,
      minuto,
    );

    final agora = tz.TZDateTime.now(tz.local);
    return [
      if (diasAntes > 0 && tx.isAfter(agora))
        (
          quando: tx,
          tipo: 'xd',
          titulo: 'Vence em $diasAntes ${diasAntes == 1 ? 'dia' : 'dias'}',
        ),
      if (diaDoVencimento.isAfter(agora))
        (
          quando: diaDoVencimento,
          tipo: 'dia',
          titulo: 'Vence hoje',
        ),
    ];
  }

  bool _vencimentoExpirado(DateTime venc) {
    final hoje = DateTime.now();
    final diaVenc = DateTime(venc.year, venc.month, venc.day);
    return !diaVenc.isAfter(hoje);
  }

  /// Envia uma notificação de teste imediatamente para o dispositivo.
  Future<bool> enviarNotificacaoTeste() async {
    if (!_inicializado) await init();
    final concedida = await pedirPermissao();
    if (!concedida) return false;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNome,
        channelDescription: 'Lembra faturas que vencem em 3 dias e no dia',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.show(
        id: 99999,
        title: '🔔 Meu Bolso',
        body: 'As notificações estão ativas e funcionando no seu dispositivo!',
        notificationDetails: details,
      );
      return true;
    } catch (e) {
      debugPrint('NotificacoesService.enviarNotificacaoTeste erro: $e');
      return false;
    }
  }

  Future<void> _agendar({
    required int id,
    required String titulo,
    required String corpo,
    required tz.TZDateTime quando,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNome,
        channelDescription: 'Lembra faturas que vencem em 3 dias e no dia',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      scheduledDate: quando,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'lembrete',
    );
  }

  /// Cancela as notificações de um lançamento.
  Future<void> cancelarPorLancamento(String id) async {
    try {
      await _plugin.cancel(id: _idNotificacao(id, 'xd'));
      await _plugin.cancel(id: _idNotificacao(id, 'dia'));
    } catch (e) {
      debugPrint('NotificacoesService.cancelarPorLancamento erro: $e');
    }
  }

  /// Cancela todas as notificações agendadas pelo app.
  Future<void> cancelarTudo() => _plugin.cancelAll();

  int _idNotificacao(String lanId, String tipo) {
    return Object.hash(_canalLembretes, lanId, tipo) & 0x7fffffff;
  }

  String _corpo(Lancamento lancamento) {
    final valor = _formataValor(lancamento.valorCents);
    final descricao = lancamento.descricao;
    return '$descricao — R\$ $valor';
  }

  String _formataValor(int centavos) {
    final reais = centavos ~/ 100;
    final resto = (centavos % 100).toString().padLeft(2, '0');
    return '$reais,$resto';
  }
}