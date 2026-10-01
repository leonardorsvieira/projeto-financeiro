import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/privacidade/data/supabase_exclusao_conta_repository.dart';
import 'package:meubolso/features/privacidade/domain/exclusao_conta_repository.dart';

void main() {
  const mensagemGenerica =
      'Não foi possível excluir a conta agora. Verifique a conexão e tente '
      'novamente.';

  EdgeFunction funcaoTeste({String? token = 'token-teste'}) => EdgeFunction(
    url: Uri.parse('https://exemplo.supabase.co/functions/v1/excluir-conta'),
    anonKey: 'anon-teste',
    tokenDeAcesso: () async => token,
  );

  group('SupabaseExclusaoContaRepository.excluirConta', () {
    test('200: completa com POST autenticado para a função', () async {
      late http.Request recebida;
      final repo = SupabaseExclusaoContaRepository(
        cliente: MockClient((req) async {
          recebida = req;
          return http.Response('{"ok":true}', 200);
        }),
        funcao: funcaoTeste(),
      );

      await repo.excluirConta();

      expect(recebida.method, 'POST');
      expect(
        recebida.url.toString(),
        'https://exemplo.supabase.co/functions/v1/excluir-conta',
      );
      expect(recebida.headers['Authorization'], 'Bearer token-teste');
      expect(recebida.headers['apikey'], 'anon-teste');
      expect(recebida.body, '{}');
    });

    test('sem token: lança sem chamar o servidor', () async {
      var chamadas = 0;
      final repo = SupabaseExclusaoContaRepository(
        cliente: MockClient((req) async {
          chamadas++;
          return http.Response('', 200);
        }),
        funcao: funcaoTeste(token: null),
      );

      await expectLater(
        repo.excluirConta(),
        throwsA(
          isA<ExclusaoContaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('sessão'),
          ),
        ),
      );
      expect(chamadas, 0);
    });

    test('401: mensagem de sessão', () async {
      final repo = SupabaseExclusaoContaRepository(
        cliente: MockClient(
          (req) async => http.Response('{"erro":"nao_autenticado"}', 401),
        ),
        funcao: funcaoTeste(),
      );

      await expectLater(
        repo.excluirConta(),
        throwsA(
          isA<ExclusaoContaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('sessão'),
          ),
        ),
      );
    });

    test('500: mensagem genérica, sem retry', () async {
      var chamadas = 0;
      final repo = SupabaseExclusaoContaRepository(
        cliente: MockClient((req) async {
          chamadas++;
          return http.Response('{"erro":"falha_ao_excluir"}', 500);
        }),
        funcao: funcaoTeste(),
      );

      await expectLater(
        repo.excluirConta(),
        throwsA(
          isA<ExclusaoContaException>().having(
            (e) => e.mensagem,
            'mensagem',
            mensagemGenerica,
          ),
        ),
      );
      expect(chamadas, 1);
    });

    test('exceção de rede: mensagem genérica', () async {
      final repo = SupabaseExclusaoContaRepository(
        cliente: MockClient((req) async => throw http.ClientException('rede')),
        funcao: funcaoTeste(),
      );

      await expectLater(
        repo.excluirConta(),
        throwsA(
          isA<ExclusaoContaException>().having(
            (e) => e.mensagem,
            'mensagem',
            mensagemGenerica,
          ),
        ),
      );
    });
  });
}
