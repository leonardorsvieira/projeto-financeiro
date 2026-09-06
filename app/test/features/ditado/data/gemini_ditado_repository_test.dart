import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meubolso/features/ditado/data/gemini_ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

void main() {
  final audio = LancamentoAudio(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'audio/webm',
  );

  http.Response corpoResposta(Map<String, dynamic> objeto) => http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': jsonEncode(objeto)},
                ],
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );

  group('GeminiDitadoRepository.reconhecer', () {
    test('faz POST para generateContent e devolve rascunho', () async {
      Uri? uriEnviada;
      String? corpoEnviado;

      final cliente = MockClient((request) async {
        uriEnviada = request.url;
        corpoEnviado = request.body;
        return corpoResposta({
          'descricao': 'Almoço',
          'valor_reais': '42,90',
          'categoria': 'Alimentação',
          'forma_pagamento': 'Pix',
          'vencimento': null,
        });
      });

      final repo = GeminiDitadoRepository(
        cliente: cliente,
        apiKey: 'chave-teste',
      );

      final rascunho = await repo.reconhecer(audio);

      expect(uriEnviada!.path, contains('gemini-2.5-flash:generateContent'));
      expect(uriEnviada!.queryParameters['key'], 'chave-teste');
      expect(corpoEnviado, contains('audio/webm'));
      expect(rascunho.descricao, 'Almoço');
      expect(rascunho.valorTexto, '42,90');
      expect(rascunho.categoria, 'Alimentação');
      expect(rascunho.formaPagamento, 'Pix');
    });

    test('lança DitadoException em HTTP diferente de 200', () {
      final cliente = MockClient(
        (_) async => http.Response('erro', 500),
      );
      final repo = GeminiDitadoRepository(cliente: cliente, apiKey: 'x');

      expect(
        () => repo.reconhecer(audio),
        throwsA(isA<DitadoException>()),
      );
    });

    test('lança DitadoException sem chave configurada', () {
      final repo = GeminiDitadoRepository(cliente: MockClient((_) async {
        return http.Response('', 200);
      }), apiKey: '');

      expect(
        () => repo.reconhecer(audio),
        throwsA(isA<DitadoException>()),
      );
    });

    test('lança DitadoException com resposta vazia', () {
      final cliente = MockClient(
        (_) async => http.Response(
          '{"candidates":[{"content":{"parts":[{"text":""}]}}]}',
          200,
        ),
      );
      final repo = GeminiDitadoRepository(cliente: cliente, apiKey: 'x');

      expect(
        () => repo.reconhecer(audio),
        throwsA(isA<DitadoException>()),
      );
    });
  });

  group('GeminiDitadoRepository.corrigirCampo', () {
    test('devolve apenas o campo corrigido', () async {
      String? corpoEnviado;
      final cliente = MockClient((request) async {
        corpoEnviado = request.body;
        return corpoResposta({'valor': '30,00'});
      });
      final repo = GeminiDitadoRepository(cliente: cliente, apiKey: 'x');

      const rascunho = RascunhoLancamento(
        descricao: 'Uber',
        valorTexto: '25,00',
      );
      final valor = await repo.corrigirCampo(
        CampoDitado.valor,
        texto: 'trinta reais',
        rascunhoAtual: rascunho,
      );

      expect(valor, '30,00');
      expect(corpoEnviado, contains('Corrija o campo'));
      expect(corpoEnviado, contains('descricao: Uber'));
    });
  });
}