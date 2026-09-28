import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/conta_bancaria_conectada.dart';

class OpenFinanceRepository {
  static const _keyContas = 'open_finance_contas_v1';
  static const _keyCapturaNotificacoes = 'open_finance_captura_notif_v1';
  // Versões antigas guardavam credenciais da Pluggy no aparelho; hoje elas
  // ficam só na Edge Function. A chave é apagada na primeira leitura.
  static const _keyPluggyCredsLegado = 'open_finance_pluggy_creds_v1';

  Future<List<ContaBancariaConectada>> getContasConectadas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPluggyCredsLegado);
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
