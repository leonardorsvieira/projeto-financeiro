import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/ditado/data/gemini_prompt.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

void main() {
  final audio = LancamentoAudio(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'audio/webm',
  );

  group('GeminiPrompt.modelo', () {
    test('é o gemini-3.5-flash-lite (nunca o 2.0 descontinuado)', () {
      expect(GeminiPrompt.modelo, 'gemini-3.5-flash-lite');
      expect(GeminiPrompt.modelo, isNot(contains('2.0')));
    });
  });

  group('payloadReconhecer', () {
    test('usa modelagem com áudio inline e resposta em JSON', () {
      final payload = GeminiPrompt.payloadReconhecer(audio);

      final sistema = payload['system_instruction'] as Map<String, dynamic>;
      final partes = payload['contents'] as List<dynamic>;
      final userParts = (partes.first as Map<String, dynamic>)['parts'] as List;

      expect(
        (sistema['parts'] as List).first['text'].toString(),
        contains('categoria deve ser escolhida APENAS entre'),
      );
      expect(
        (sistema['parts'] as List).first['text'].toString(),
        contains('Alimentação'),
      );
      expect(
        (sistema['parts'] as List).first['text'].toString(),
        contains('Pix'),
      );
      expect(userParts, hasLength(2));
      final inline =
          (userParts[1] as Map<String, dynamic>)['inline_data'] as Map;
      expect(inline['mime_type'], 'audio/webm');
      expect(inline['data'], 'AQID');
    });

    test('resposta é JSON com temperature baixa', () {
      final payload = GeminiPrompt.payloadReconhecer(audio);
      final config = payload['generation_config'] as Map<String, dynamic>;
      expect(config['response_mime_type'], 'application/json');
      expect(config['temperature'], lessThanOrEqualTo(0.5));
    });

    test('instrução menciona a data de hoje para contexto', () {
      final payload = GeminiPrompt.payloadReconhecer(audio);
      final sistema = payload['system_instruction'] as Map<String, dynamic>;
      final hoje = DateTime.now();
      expect(
        (sistema['parts'] as List).first['text'].toString(),
        contains('Hoje é ${hoje.year}-'),
      );
    });

    test('instrução reforça lista fixa com fallback e mapeamentos', () {
      final payload = GeminiPrompt.payloadReconhecer(audio);
      final sistema = payload['system_instruction'] as Map<String, dynamic>;
      final instrucao = (sistema['parts'] as List).first['text'].toString();
      expect(instrucao, contains('use "Outros" para categoria e "Outro" para forma de pagamento'));
      expect(instrucao, contains('gás/IPTU = Moradia'));
      expect(instrucao, contains('Não preencha data só porque conhece o dia'));
    });
  test('instrução reforça lista fixa com fallback e mapeamentos', () {
      final payload = GeminiPrompt.payloadReconhecer(audio);
      final sistema = payload['system_instruction'] as Map<String, dynamic>;
      final instrucao = (sistema['parts'] as List).first['text'].toString();
      expect(instrucao, contains('use "Outros" para categoria e "Outro" para forma de pagamento'));
      expect(instrucao, contains('gás/IPTU = Moradia'));
      expect(instrucao, contains('Não preencha data só porque conhece o dia'));
    });
  });

  group('payloadCorrigir', () {
    test('inclui rascunho atual, texto e instrução do campo', () {
      const rascunho = RascunhoLancamento(
        descricao: 'Uber',
        valorTexto: '25,00',
        categoria: 'Transporte',
      );
      final payload = GeminiPrompt.payloadCorrigir(
        CampoDitado.valor,
        texto: 'trinta reais',
        rascunhoAtual: rascunho,
      );

      final sistema = payload['system_instruction'] as Map<String, dynamic>;
      final textoSistema = (sistema['parts'] as List).first['text'].toString();
      expect(textoSistema, contains('{"valor"'));
      expect(textoSistema, contains('Alimentação'));

      final partes = payload['contents'] as List;
      final userParts = (partes.first as Map<String, dynamic>)['parts'] as List;
      final contexto = (userParts.first as Map<String, dynamic>)['text'].toString();
      expect(contexto, contains('descricao: Uber'));
      expect(contexto, contains('"valor"'));
      expect(userParts, hasLength(2));
      expect((userParts[1] as Map<String, dynamic>)['text'], 'trinta reais');
    });

    test('envia áudio quando fornecido em vez de texto', () {
      final payload = GeminiPrompt.payloadCorrigir(
        CampoDitado.categoria,
        audio: audio,
      );

      final partes = payload['contents'] as List;
      final userParts = (partes.first as Map<String, dynamic>)['parts'] as List;
      final inline =
          (userParts[1] as Map<String, dynamic>)['inline_data'] as Map;
      expect(inline['mime_type'], 'audio/webm');
    });
  });

  group('parseRascunho', () {
    test('extrai JSON completo ignorando ruído', () {
      final texto = 'Aqui está: \n{"descricao": "Almoço", '
          '"valor_reais": "42,90", "categoria": "Alimentação", '
          '"forma_pagamento": "Pix", "data": "2026-09-06", '
          '"vencimento": null} \nesse é o resultado';

      final rascunho = GeminiPrompt.parseRascunho(texto);

      expect(rascunho.descricao, 'Almoço');
      expect(rascunho.valorTexto, '42,90');
      expect(rascunho.categoria, 'Alimentação');
      expect(rascunho.formaPagamento, 'Pix');
      expect(rascunho.dataIso, '2026-09-06');
      expect(rascunho.vencimentoIso, isNull);
      expect(rascunho.tipo, isNull);
    });

    test('extrai tipo da resposta', () {
      final rascunho = GeminiPrompt.parseRascunho(
        '{"descricao": "Salário", "valor_reais": "3000,00", '
        '"tipo": "receita", "categoria": "Outros"}',
      );

      expect(rascunho.tipo, 'receita');
      expect(rascunho.descricao, 'Salário');
    });

    test('lança DitadoException sem JSON', () {
      expect(
        () => GeminiPrompt.parseRascunho('desculpe, não entendi'),
        throwsA(isA<DitadoException>()),
      );
    });
  });

  group('parseCorrecao', () {
    test('retorna valor do campo corrigido', () {
      expect(
        GeminiPrompt.parseCorrecao('{"valor": "30,00"}', CampoDitado.valor),
        '30,00',
      );
    });

    test('retorna null quando campo ausente ou null', () {
      expect(
        GeminiPrompt.parseCorrecao('{"descricao": null}', CampoDitado.valor),
        isNull,
      );
      expect(
        GeminiPrompt.parseCorrecao('{}', CampoDitado.valor),
        isNull,
      );
    });
  });

  group('textoResposta', () {
    test('junta textos dos candidates', () {
      final resposta = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '{"descricao": "Uber"}'},
              ],
            },
          },
        ],
      };

      expect(GeminiPrompt.textoResposta(resposta), '{"descricao": "Uber"}');
    });

    test('retorna null sem candidates', () {
      expect(GeminiPrompt.textoResposta({'candidates': []}), isNull);
    });
  });
}