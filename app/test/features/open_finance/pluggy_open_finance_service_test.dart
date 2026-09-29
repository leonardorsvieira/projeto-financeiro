import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';

final _funcao = EdgeFunction(
  url: Uri.parse('https://exemplo.supabase.co/functions/v1/pluggy'),
  anonKey: 'anon-teste',
  tokenDeAcesso: () async => 'token-usuario',
);

/// Simula a Edge Function `pluggy`: decodifica `{metodo, caminho, corpo}` e
/// entrega ao [handler] como se fosse a API da Pluggy.
MockClient _proxy(
  Future<http.Response> Function(
    String metodo,
    Uri caminho,
    Map<String, dynamic>? corpo,
  ) handler,
) {
  return MockClient((request) async {
    expect(request.url, _funcao.url);
    expect(request.headers['Authorization'], 'Bearer token-usuario');
    expect(request.headers.containsKey('X-API-KEY'), isFalse);
    final env = jsonDecode(request.body) as Map<String, dynamic>;
    return handler(
      env['metodo'] as String,
      Uri.parse(env['caminho'] as String),
      env['corpo'] as Map<String, dynamic>?,
    );
  });
}

PluggyOpenFinanceService _service(MockClient cliente) =>
    PluggyOpenFinanceService(httpClient: cliente, funcao: _funcao);

void main() {
  group('PluggyOpenFinanceService', () {
    test('verificarConfiguracao lê /status do servidor', () async {
      final service = _service(_proxy((metodo, caminho, _) async {
        if (metodo == 'GET' && caminho.path == '/status') {
          return http.Response(jsonEncode({'configurado': true}), 200);
        }
        return http.Response('', 404);
      }));

      expect(await service.verificarConfiguracao(), isTrue);
    });

    test('sem usuário logado não chama o servidor', () async {
      var chamadas = 0;
      final service = PluggyOpenFinanceService(
        httpClient: MockClient((_) async {
          chamadas++;
          return http.Response('', 200);
        }),
        funcao: EdgeFunction(
          url: _funcao.url,
          anonKey: 'anon-teste',
          tokenDeAcesso: () async => null,
        ),
      );

      expect(await service.verificarConfiguracao(), isFalse);
      await expectLater(service.buscarItemPorId('x'), throwsException);
      expect(chamadas, 0);
    });

    test('buscarItensConectados mapeia itens e contas da Pluggy corretamente', () async {
      final service = _service(_proxy((metodo, caminho, _) async {
        if (caminho.path == '/items') {
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
        if (caminho.path == '/accounts') {
          expect(caminho.queryParameters['itemId'], 'item_nubank_1');
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
      }));

      final contas = await service.buscarItensConectados();
      expect(contas.length, equals(1));
      expect(contas.first.nomeBanco, equals('Nubank'));
      expect(contas.first.corHex, equals('#8A05BE'));
      expect(contas.first.mascaraCartao, equals('•••• 5678'));
    });

    test('item de outro usuário (404 do servidor) mantém a conta local sem dados', () async {
      final service = _service(_proxy((_, caminho, _) async {
        if (caminho.path == '/items') {
          return http.Response(jsonEncode({'results': []}), 200);
        }
        return http.Response('{"erro":"item_nao_encontrado"}', 404);
      }));

      await expectLater(
        service.buscarItemPorId('item_de_outra_pessoa'),
        throwsException,
      );
    });

    test('buscarTodasTransacoes extrai e mapeia transações reais', () async {
      final service = _service(_proxy((_, caminho, _) async {
        if (caminho.path == '/items') {
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
        if (caminho.path == '/accounts') {
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
        if (caminho.path == '/v2/transactions') {
          expect(caminho.queryParameters['accountId'], 'acc_inter_1');
          // Paginação por cursor: 1ª página aponta a 2ª em `next`.
          if (caminho.queryParameters['after'] == null) {
            expect(caminho.queryParameters['dateFrom'], isNotNull);
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
                ],
                'next': 'accountId=acc_inter_1&after=cursor_2',
              }),
              200,
            );
          }
          expect(caminho.queryParameters['after'], 'cursor_2');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'tx_cred_002',
                  'description': 'Depósito recebido',
                  'amount': 500.00,
                  'type': 'CREDIT',
                  'date': '2026-09-28T11:00:00Z',
                }
              ],
              'next': null,
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }));

      final transacoes = await service.buscarTodasTransacoes();
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

    test('cartão: compra é saída, estorno é entrada e pagamento de fatura é ignorado',
        () async {
      final service = _service(_proxy((_, caminho, _) async {
        if (caminho.path == '/accounts') {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 'cc_1', 'type': 'CREDIT', 'name': 'Nubank'},
              ],
            }),
            200,
          );
        }
        if (caminho.path == '/v2/transactions') {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 'compra', 'description': 'Mercado', 'amount': 120.0,
                  'type': 'CREDIT', 'date': '2026-09-20T10:00:00Z'},
                {'id': 'estorno', 'description': 'Estorno loja', 'amount': -50.0,
                  'type': 'DEBIT', 'date': '2026-09-21T10:00:00Z'},
                {'id': 'fatura', 'description': 'Pagamento recebido',
                  'amount': -900.0, 'date': '2026-09-22T10:00:00Z'},
              ],
              'next': null,
            }),
            200,
          );
        }
        return http.Response('', 404);
      }));

      final transacoes = await service.buscarTodasTransacoes(
        contas: [
          ContaBancariaConectada(
            id: 'item_cc',
            nomeBanco: 'Nubank',
            tipoConta: 'Cartão',
            corHex: '#8A05BE',
            ultimoSync: DateTime(2026, 9, 28),
            status: StatusConexaoBanco.conectado,
            itemIdPluggy: 'item_cc',
          ),
        ],
      );

      expect(transacoes.map((t) => t.id), ['compra', 'estorno']);
      expect(transacoes.firstWhere((t) => t.id == 'compra').isReceita, isFalse);
      expect(transacoes.firstWhere((t) => t.id == 'estorno').isReceita, isTrue);
    });

    test('gerarConnectToken faz POST /connect_token e retorna token', () async {
      final service = _service(_proxy((metodo, caminho, corpo) async {
        if (caminho.path == '/connect_token' && metodo == 'POST') {
          expect(corpo!['options']['connectorId'], equals(200));
          return http.Response(jsonEncode({'accessToken': 'connect_token_12345'}), 200);
        }
        return http.Response('Error', 400);
      }));

      final token = await service.gerarConnectToken(connectorId: 200);
      expect(token, equals('connect_token_12345'));
    });

    test('buscarItemPorId busca dados de um item específico', () async {
      final service = _service(_proxy((_, caminho, _) async {
        if (caminho.path == '/items/item_meu_pluggy') {
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
        if (caminho.path == '/accounts') {
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
      }));

      final item = await service.buscarItemPorId('item_meu_pluggy');
      expect(item.id, equals('item_meu_pluggy'));
      expect(item.nomeBanco, equals('MeuPluggy'));
      expect(item.corHex, equals('#EF294B'));
      expect(item.mascaraCartao, equals('•••• 5432'));
    });

    test('Meu Pluggy: espera o link de autorização ficar pronto', () async {
      var consultas = 0;
      final service = PluggyOpenFinanceService(
        httpClient: _proxy((metodo, caminho, _) async {
          if (metodo == 'POST' && caminho.path == '/items') {
            return http.Response(jsonEncode({'id': 'item_mp'}), 201);
          }
          if (caminho.path == '/items/item_mp') {
            consultas++;
            return http.Response(
              jsonEncode({
                'id': 'item_mp',
                if (consultas >= 2)
                  'parameter': {'data': 'https://meu.pluggy.ai/oauth?x=1'},
              }),
              200,
            );
          }
          return http.Response('', 404);
        }),
        funcao: _funcao,
        esperasAutorizacao: List.filled(5, Duration.zero),
      );

      final r = await service.iniciarConexaoMeuPluggyDireta();
      expect(r.itemId, 'item_mp');
      expect(r.oauthUrl, 'https://meu.pluggy.ai/oauth?x=1');
      expect(consultas, 2);
    });

    test('Meu Pluggy sem link: widget continua o MESMO item (sem id inventado)', () async {
      Map<String, dynamic>? corpoToken;
      final service = PluggyOpenFinanceService(
        httpClient: _proxy((metodo, caminho, corpo) async {
          if (metodo == 'POST' && caminho.path == '/items') {
            return http.Response(jsonEncode({'id': 'item_mp'}), 201);
          }
          if (caminho.path == '/items/item_mp') {
            return http.Response(jsonEncode({'id': 'item_mp'}), 200);
          }
          if (caminho.path == '/connect_token') {
            corpoToken = corpo;
            return http.Response(jsonEncode({'accessToken': 'tok'}), 200);
          }
          return http.Response('', 404);
        }),
        funcao: _funcao,
        esperasAutorizacao: List.filled(2, Duration.zero),
      );

      final r = await service.iniciarConexaoMeuPluggyDireta();
      expect(r.itemId, 'item_mp');
      expect(r.oauthUrl, 'https://connect.pluggy.ai/?connect_token=tok');
      expect(corpoToken!['itemId'], 'item_mp');
    });

    test('Meu Pluggy: usa o nome do banco da conta em vez de "MeuPluggy"',
        () async {
      final service = _service(_proxy((_, caminho, _) async {
        if (caminho.path == '/items/item_mp') {
          return http.Response(
            jsonEncode({
              'id': 'item_mp',
              'connector': {'id': 200, 'name': 'MeuPluggy'},
              'status': 'UPDATED',
            }),
            200,
          );
        }
        if (caminho.path == '/accounts') {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 'a1', 'type': 'BANK', 'name': 'Nubank', 'number': '1234'},
              ],
            }),
            200,
          );
        }
        return http.Response('', 404);
      }));

      final conta = await service.buscarItemPorId('item_mp');
      expect(conta.nomeBanco, 'Nubank');
    });

    test('removerTodasConexoes pede DELETE /items ao servidor', () async {
      String? metodoEnviado;
      final service = _service(_proxy((metodo, caminho, _) async {
        if (caminho.path == '/items') {
          metodoEnviado = metodo;
          return http.Response(jsonEncode({'removidas': 3, 'total': 3}), 200);
        }
        return http.Response('', 404);
      }));

      expect(await service.removerTodasConexoes(), 3);
      expect(metodoEnviado, 'DELETE');
    });

    test('limite diário vira mensagem clara', () async {
      final service = _service(_proxy(
        (_, _, _) async => http.Response('{"erro":"limite_diario"}', 429),
      ));

      await expectLater(
        service.gerarConnectToken(),
        throwsA(predicate((e) => e.toString().contains('Limite diário'))),
      );
    });
  });
}
