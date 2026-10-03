import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../domain/indicadores_mercado.dart';

/// Indicadores pela Edge Function `indicadores` (o app não chama Banco Central
/// nem IBGE direto). Qualquer falha vira null: o guia sai sem eles.
class EdgeIndicadoresRepository implements IndicadoresRepository {
  EdgeIndicadoresRepository({http.Client? cliente, EdgeFunction? funcao})
      : _cliente = cliente ?? http.Client(),
        _funcao = funcao ?? EdgeFunction.supabase('indicadores');

  final http.Client _cliente;
  final EdgeFunction _funcao;

  @override
  Future<IndicadoresMercado?> buscar() async {
    try {
      final cabecalhos = await _funcao.cabecalhos();
      if (cabecalhos == null) return null;
      final resposta = await _cliente
          .post(_funcao.url, headers: cabecalhos, body: '{}')
          .timeout(const Duration(seconds: 20));
      if (resposta.statusCode != 200) {
        debugPrint('Indicadores indisponíveis: HTTP ${resposta.statusCode}');
        return null;
      }
      final json = jsonDecode(resposta.body);
      if (json is! Map<String, dynamic>) return null;
      final indicadores = IndicadoresMercado.fromJson(json);
      return indicadores.vazio ? null : indicadores;
    } on Object catch (e) {
      debugPrint('Indicadores indisponíveis: $e');
      return null;
    }
  }
}
