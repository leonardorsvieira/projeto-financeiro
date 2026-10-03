import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/consultoria/data/gemini_consultoria_repository.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';
import 'package:meubolso/features/ditado/data/gemini_prompt.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';

void main() {
  const perfil = PerfilInvestidor(
    objetivo: ObjetivoInvestimento.reserva,
    prazo: PrazoInvestimento.curto,
    risco: ToleranciaRisco.conservador,
  );

  final funcao = EdgeFunction(
    url: Uri.parse('https://exemplo.supabase.co/functions/v1/ditado'),
    anonKey: 'anon-teste',
    tokenDeAcesso: () async => 'token-teste',
  );

  http.Response ok(String texto) => http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': texto},
                ],
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  GeminiConsultoriaRepository repo(MockClient cliente) =>
      GeminiConsultoriaRepository(
        cliente: cliente,
        funcao: funcao,
        esperasRetry: const [],
        relogio: () => DateTime(2026, 10, 3, 9),
      );

  test('pede ao modelo padrão, com a Busca Google, e devolve o guia', () async {
    final pedidos = <Map<String, dynamic>>[];
    final guia = await repo(MockClient((req) async {
      pedidos.add(jsonDecode(req.body) as Map<String, dynamic>);
      return ok('## Sua situação hoje\nOk.');
    })).gerar(dadosCliente: 'Sobra: R\$ 10,00', perfil: perfil);

    expect(pedidos, hasLength(1));
    expect(pedidos.single['modelo'], GeminiPrompt.modelo);
    final corpo = pedidos.single['corpo'] as Map<String, dynamic>;
    expect(corpo['tools'], [
      {'google_search': <String, dynamic>{}},
    ]);
    expect(guia.texto, '## Sua situação hoje\nOk.');
    expect(guia.geradoEm, DateTime(2026, 10, 3, 9));
  });

  test('limite diário do guia vira mensagem clara, sem repetir', () async {
    var chamadas = 0;
    final r = repo(MockClient((_) async {
      chamadas++;
      return http.Response('{"erro":"limite_diario_consultoria"}', 429);
    }));

    await expectLater(
      r.gerar(dadosCliente: '', perfil: perfil),
      throwsA(isA<DitadoException>().having(
        (e) => e.mensagem,
        'mensagem',
        contains('máximo de guias de investimento de hoje'),
      )),
    );
    expect(chamadas, 1);
  });

  test('modelo que recusa troca para o gemini-2.5-flash; no máximo 2 '
      'modelos × 2 tentativas', () async {
    final modelos = <String>[];
    final r = repo(MockClient((req) async {
      final modelo = (jsonDecode(req.body) as Map)['modelo'] as String;
      modelos.add(modelo);
      if (modelo == 'gemini-2.5-flash') return ok('Guia');
      return http.Response('{"error":{"status":"INVALID_ARGUMENT"}}', 400);
    }));

    final guia = await r.gerar(dadosCliente: '', perfil: perfil);
    expect(guia.texto, 'Guia');
    expect(modelos, [GeminiPrompt.modelo, 'gemini-2.5-flash']);

    var chamadas = 0;
    await expectLater(
      repo(MockClient((_) async {
        chamadas++;
        return http.Response('', 503);
      })).gerar(dadosCliente: '', perfil: perfil),
      throwsA(isA<DitadoException>()),
    );
    expect(chamadas, 4);
  });
}
