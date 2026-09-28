import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/conta_bancaria_conectada.dart';

class PluggyCredentials {
  final String? clientId;
  final String? clientSecret;
  final String? apiKey;

  const PluggyCredentials({
    this.clientId,
    this.clientSecret,
    this.apiKey,
  });

  bool get isPreenchido =>
      (clientId != null && clientId!.trim().isNotEmpty && clientSecret != null && clientSecret!.trim().isNotEmpty) ||
      (apiKey != null && apiKey!.trim().isNotEmpty);

  Map<String, dynamic> toMap() => {
        'client_id': clientId,
        'client_secret': clientSecret,
        'api_key': apiKey,
      };

  factory PluggyCredentials.fromMap(Map<String, dynamic> map) => PluggyCredentials(
        clientId: map['client_id'] as String?,
        clientSecret: map['client_secret'] as String?,
        apiKey: map['api_key'] as String?,
      );
}

class OpenFinanceRepository {
  static const _keyContas = 'open_finance_contas_v1';
  static const _keyCapturaNotificacoes = 'open_finance_captura_notif_v1';
  static const _keyPluggyCreds = 'open_finance_pluggy_creds_v1';

  Future<PluggyCredentials?> getPluggyCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPluggyCreds);
    if (raw == null || raw.isEmpty) return null;
    try {
      return PluggyCredentials.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarPluggyCredentials(PluggyCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPluggyCreds, jsonEncode(creds.toMap()));
  }

  Future<void> limparPluggyCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPluggyCreds);
  }

  Future<List<ContaBancariaConectada>> getContasConectadas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyContas);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((item) =>
              ContaBancariaConectada.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> salvarContasConectadas(List<ContaBancariaConectada> contas) async {
    final prefs = await SharedPreferences.getInstance();
    final listMap = contas.map((c) => c.toMap()).toList();
    await prefs.setString(_keyContas, jsonEncode(listMap));
  }

  Future<void> adicionarConta(ContaBancariaConectada novaConta) async {
    final atuais = await getContasConectadas();
    atuais.add(novaConta);
    await salvarContasConectadas(atuais);
  }

  Future<void> removerConta(String id) async {
    final atuais = await getContasConectadas();
    atuais.removeWhere((c) => c.id == id);
    await salvarContasConectadas(atuais);
  }

  Future<bool> isCapturaNotificacoesAtiva() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCapturaNotificacoes) ?? true;
  }

  Future<void> setCapturaNotificacoesAtiva(bool ativa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCapturaNotificacoes, ativa);
  }
}
