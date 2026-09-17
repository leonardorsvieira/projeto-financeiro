import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meubolso/features/investimentos/data/cotacoes_service.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';

void main() {
  group('CotacoesService', () {
    test('buscarPrecoCents para Ações da B3 via Yahoo Finance', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('PETR4.SA')) {
          return http.Response(
            jsonEncode({
              'chart': {
                'result': [
                  {
                    'meta': {'regularMarketPrice': 38.50}
                  }
                ]
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CotacoesService(client: mockClient);
      final precoCents = await service.buscarPrecoCents('PETR4', TipoClasseInvestimento.acao);

      expect(precoCents, 3850);
    });

    test('buscarPrecoCents para FIIs via Yahoo Finance', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('MXRF11.SA')) {
          return http.Response(
            jsonEncode({
              'chart': {
                'result': [
                  {
                    'meta': {'regularMarketPrice': 9.85}
                  }
                ]
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CotacoesService(client: mockClient);
      final precoCents = await service.buscarPrecoCents('MXRF11', TipoClasseInvestimento.fii);

      expect(precoCents, 985);
    });

    test('buscarPrecoCents para Cripto via AwesomeAPI', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('BTC-BRL')) {
          return http.Response(
            jsonEncode({
              'BTCBRL': {
                'code': 'BTC',
                'bid': '400000.00',
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CotacoesService(client: mockClient);
      final precoCents = await service.buscarPrecoCents('BITCOIN', TipoClasseInvestimento.cripto);

      expect(precoCents, 40000000);
    });

    test('retorna null se ticker não for encontrado ou erro HTTP', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = CotacoesService(client: mockClient);
      final precoCents = await service.buscarPrecoCents('INVALIDO123', TipoClasseInvestimento.acao);

      expect(precoCents, isNull);
    });
  });
}
