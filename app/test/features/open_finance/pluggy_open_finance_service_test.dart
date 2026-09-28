import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meubolso/features/open_finance/data/open_finance_repository.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';

void main() {
  group('PluggyOpenFinanceService', () {
    test('obterApiKey retorna a apiKey direta quando fornecida', () async {
      final service = PluggyOpenFinanceService();
      const creds = PluggyCredentials(apiKey: 'meu_token_direto_123');

      final key = await service.obterApiKey(creds);
      expect(key, equals('meu_token_direto_123'));
    });

    test('obterApiKey faz POST /auth com clientId e secret', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['clientId'] == 'cid_123' && body['clientSecret'] == 'sec_456') {
            return http.Response(jsonEncode({'apiKey': 'jwt_gerado_789'}), 200);
          }
        }
        return http.Response('Unauthorized', 401);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(
        clientId: 'cid_123',
        clientSecret: 'sec_456',
      );

      final key = await service.obterApiKey(creds);
      expect(key, equals('jwt_gerado_789'));
    });

    test('testarConexao retorna true quando /items responde 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/items' &&
            request.headers['X-API-KEY'] == 'token_valido') {
          return http.Response(jsonEncode({'results': []}), 200);
        }
        return http.Response('Unauthorized', 401);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(apiKey: 'token_valido');

      final ok = await service.testarConexao(creds);
      expect(ok, isTrue);
    });

    test('buscarItensConectados mapeia itens e contas da Pluggy corretamente', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/items') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'item_nubank_1',
                  'connector': {
                    'name': 'Nubank',
                    'primaryColor': '#8A05BE',
                  },
                  'status': 'UPDATED',
                  'lastUpdatedAt': '2026-09-28T12:00:00Z',
                }
              ]
            }),
            200,
          );
        }
        if (request.url.path == '/accounts') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'acc_1',
                  'type': 'CREDIT',
                  'number': '12345678',
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(apiKey: 'token_valido');

      final contas = await service.buscarItensConectados(creds);
      expect(contas.length, equals(1));
      expect(contas.first.nomeBanco, equals('Nubank'));
      expect(contas.first.corHex, equals('#8A05BE'));
      expect(contas.first.mascaraCartao, equals('•••• 5678'));
    });

    test('buscarTodasTransacoes extrai e mapeia transações reais', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/items') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'item_inter_1',
                  'connector': {
                    'name': 'Banco Inter',
                    'primaryColor': '#FF7A00',
                  },
                  'status': 'UPDATED',
                }
              ]
            }),
            200,
          );
        }
        if (request.url.path == '/accounts') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'acc_inter_1',
                  'type': 'BANK',
                }
              ]
            }),
            200,
          );
        }
        if (request.url.path == '/transactions') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'tx_pix_001',
                  'description': 'Pix enviado para Maria',
                  'amount': -35.50,
                  'type': 'DEBIT',
                  'date': '2026-09-28T10:30:00Z',
                  'category': 'Food & Beverage',
                  'paymentData': {'paymentMethod': 'PIX'},
                },
                {
                  'id': 'tx_cred_002',
                  'description': 'Depósito recebido',
                  'amount': 500.00,
                  'type': 'CREDIT',
                  'date': '2026-09-28T11:00:00Z',
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(apiKey: 'token_valido');

      final transacoes = await service.buscarTodasTransacoes(creds);
      expect(transacoes.length, equals(2));

      final pix = transacoes.firstWhere((t) => t.id == 'tx_pix_001');
      expect(pix.valorCents, equals(3550));
      expect(pix.isReceita, isFalse);
      expect(pix.formaPagamento, equals('Pix'));
      expect(pix.categoriaSugerida, equals('Alimentação'));

      final deposito = transacoes.firstWhere((t) => t.id == 'tx_cred_002');
      expect(deposito.valorCents, equals(50000));
      expect(deposito.isReceita, isTrue);
    });

    test('gerarConnectToken faz POST /connect_token e retorna token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/connect_token' &&
            request.method == 'POST' &&
            request.headers['X-API-KEY'] == 'token_valido') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['options']['connectorId'], equals(200));
          return http.Response(jsonEncode({'accessToken': 'connect_token_12345'}), 200);
        }
        return http.Response('Error', 400);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(apiKey: 'token_valido');

      final token = await service.gerarConnectToken(creds, connectorId: 200);
      expect(token, equals('connect_token_12345'));
    });

    test('buscarItemPorId busca dados de um item específico', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/items/item_meu_pluggy') {
          return http.Response(
            jsonEncode({
              'id': 'item_meu_pluggy',
              'connector': {
                'name': 'MeuPluggy',
                'primaryColor': '#EF294B',
              },
              'status': 'UPDATED',
              'lastUpdatedAt': '2026-09-28T12:00:00Z',
            }),
            200,
          );
        }
        if (request.url.path == '/accounts') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'acc_mp_1',
                  'type': 'CREDIT',
                  'number': '98765432',
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = PluggyOpenFinanceService(httpClient: mockClient);
      const creds = PluggyCredentials(apiKey: 'token_valido');

      final item = await service.buscarItemPorId(creds, 'item_meu_pluggy');
      expect(item.id, equals('item_meu_pluggy'));
      expect(item.nomeBanco, equals('MeuPluggy'));
      expect(item.corHex, equals('#EF294B'));
      expect(item.mascaraCartao, equals('•••• 5432'));
    });
  });
}
