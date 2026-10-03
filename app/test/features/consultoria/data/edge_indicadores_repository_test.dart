import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/consultoria/data/edge_indicadores_repository.dart';

void main() {
  EdgeFunction funcao({String? token = 'token-teste'}) => EdgeFunction(
        url: Uri.parse('https://exemplo.supabase.co/functions/v1/indicadores'),
        anonKey: 'anon-teste',
        tokenDeAcesso: () async => token,
      );

  test('lê os indicadores da Edge Function', () async {
    late http.Request pedido;
    final repo = EdgeIndicadoresRepository(
      funcao: funcao(),
      cliente: MockClient((req) async {
        pedido = req;
        return http.Response(
          jsonEncode({
            'consultadoEm': '2026-10-03T18:40:00.000Z',
            'selic': {'meta': 13.75, 'reuniao': '2026-09-16', 'anterior': 14.0},
          }),
          200,
        );
      }),
    );

    final i = await repo.buscar();
    expect(i?.selicMeta, 13.75);
    expect(pedido.method, 'POST');
    expect(pedido.headers['Authorization'], 'Bearer token-teste');
  });

  test('erro da função, resposta vazia ou sem login viram null', () async {
    final erro = EdgeIndicadoresRepository(
      funcao: funcao(),
      cliente: MockClient((_) async => http.Response('{}', 503)),
    );
    expect(await erro.buscar(), isNull);

    final vazio = EdgeIndicadoresRepository(
      funcao: funcao(),
      cliente: MockClient((_) async => http.Response(
            '{"selic":null,"focus":null,"ipca12m":null,"dolar":null}',
            200,
          )),
    );
    expect(await vazio.buscar(), isNull);

    var chamou = false;
    final semLogin = EdgeIndicadoresRepository(
      funcao: funcao(token: null),
      cliente: MockClient((_) async {
        chamou = true;
        return http.Response('{}', 200);
      }),
    );
    expect(await semLogin.buscar(), isNull);
    expect(chamou, isFalse);
  });
}
