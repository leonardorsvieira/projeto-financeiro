import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/ditado/data/gemini_ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

void main() {
  final audio = LancamentoAudio(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'audio/webm',
  );

  EdgeFunction funcaoTeste({String? token = 'token-teste'}) => EdgeFunction(
        url: Uri.parse('https://exemplo.supabase.co/functions/v1/ditado'),
        anonKey: 'anon-teste',
        tokenDeAcesso: () async => token,
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
    test('não repete nem troca de modelo ao atingir o limite diário', () async {
      var chamadas = 0;
      final cliente = MockClient((_) async {
        chamadas++;
        return http.Response('{"erro":"limite_diario"}', 429);
      });
      final repo = GeminiDitadoRepository(
        cliente: cliente,
        funcao: funcaoTeste(),
        esperasRetry: const [],
      );

      await expectLater(
        repo.reconhecer(audio),
        throwsA(
          isA<DitadoException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('limite diário'),
          ),
        ),
      );
      expect(chamadas, 1);
    });

    test('conta sem acesso ativo vira mensagem clara, sem retry nem troca de modelo',
        () async {
      var chamadas = 0;
      final cliente = MockClient((_) async {
        chamadas++;
        return http.Response('{"erro":"acesso_inativo"}', 403);
      });
      final repo = GeminiDitadoRepository(
        cliente: cliente,
        funcao: funcaoTeste(),
        esperasRetry: const [],
      );

      await expectLater(
        repo.reconhecer(audio),
        throwsA(
          isA<DitadoException>().having(
            (e) => e.mensagem,
            'mensagem',
            mensagemAcessoInativo,
          ),
        ),
      );
      expect(chamadas, 1);
    });

    test('faz POST para generateContent e devolve rascunho', () async {
      Uri? uriEnviada;
      String? corpoEnviado;
      Map<String, String>? cabecalhosEnviados;

      final cliente = MockClient((request) async {
        uriEnviada = request.url;
        cabecalhosEnviados = request.headers;
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
        funcao: funcaoTeste(),
      );

      final rascunho = await repo.reconhecer(audio);

      expect(uriEnviada, funcaoTeste().url);
      expect(cabecalhosEnviados!['Authorization'], 'Bearer token-teste');
      final enviado = jsonDecode(corpoEnviado!) as Map<String, dynamic>;
      expect(enviado['modelo'], 'gemini-3.5-flash-lite');
      expect(corpoEnviado, contains('audio/webm'));
      expect(corpoEnviado, isNot(contains('key=')));
      expect(rascunho.descricao, 'Almoço');
      expect(rascunho.valorTexto, '42,90');
      expect(rascunho.categoria, 'Alimentação');
      expect(rascunho.formaPagamento, 'Pix');
    });

    test('lança DitadoException em HTTP diferente de 200 após retries', () {
      final cliente = MockClient(
        (_) async => http.Response('erro', 500),
      );
      final repo = GeminiDitadoRepository(
        cliente: cliente,
        funcao: funcaoTeste(),
        esperasRetry: const [],
      );

      expect(
        () => repo.reconhecer(audio),
        throwsA(isA<DitadoException>()),
      );
    });

    test('reconhecer tenta de novo em 503 e aceita na segunda tentativa',
        () async {
      var chamadas = 0;
      final cliente = MockClient((_) async {
        chamadas++;
        if (chamadas == 1) return http.Response('erro', 503);
        return corpoResposta({
          'descricao': 'Almoço',
          'valor_reais': '42,90',
          'categoria': 'Alimentação',
        });
      });
      final repo = GeminiDitadoRepository(
        cliente: cliente,
        funcao: funcaoTeste(),
        esperasRetry: const [],
      );

      final rascunho = await repo.reconhecer(audio);

      expect(chamadas, 2);
      expect(rascunho.descricao, 'Almoço');
      expect(rascunho.valorTexto, '42,90');
    });

    test('lança DitadoException sem usuário logado', () {
      final repo = GeminiDitadoRepository(cliente: MockClient((_) async {
        return http.Response('', 200);
      }), funcao: funcaoTeste(token: null));

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
      final repo = GeminiDitadoRepository(cliente: cliente, funcao: funcaoTeste());

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
      final repo = GeminiDitadoRepository(cliente: cliente, funcao: funcaoTeste());

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