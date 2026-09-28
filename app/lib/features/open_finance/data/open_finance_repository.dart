import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/conta_bancaria_conectada.dart';

class OpenFinanceRepository {
  static const _keyContas = 'open_finance_contas_v1';
  static const _keyCapturaNotificacoes = 'open_finance_captura_notif_v1';

  Future<List<ContaBancariaConectada>> getContasConectadas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyContas);
    if (raw == null || raw.isEmpty) {
      final padrao = [
        ContaBancariaConectada(
          id: 'nubank_default',
          nomeBanco: 'Nubank',
          tipoConta: 'Cartão & Conta',
          corHex: '#8A05BE',
          ultimoSync: DateTime.now().subtract(const Duration(minutes: 15)),
          status: StatusConexaoBanco.conectado,
          mascaraCartao: '•••• 4092',
          capturaAutomaticaAtiva: true,
        ),
        ContaBancariaConectada(
          id: 'inter_default',
          nomeBanco: 'Banco Inter',
          tipoConta: 'Conta Corrente & Pix',
          corHex: '#FF7A00',
          ultimoSync: DateTime.now().subtract(const Duration(hours: 2)),
          status: StatusConexaoBanco.conectado,
          capturaAutomaticaAtiva: true,
        ),
      ];
      await salvarContasConectadas(padrao);
      return padrao;
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
