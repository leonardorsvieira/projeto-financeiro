import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../domain/exclusao_conta_repository.dart';

/// Chama a Edge Function `excluir-conta` com o JWT do usuário. O servidor
/// descobre quem excluir só pelo JWT; o corpo vai vazio. Sem retry: é uma
/// operação destrutiva e o usuário decide se tenta de novo.
class SupabaseExclusaoContaRepository implements ExclusaoContaRepository {
  SupabaseExclusaoContaRepository({http.Client? cliente, EdgeFunction? funcao})
    : _cliente = cliente ?? http.Client(),
      _funcao = funcao ?? EdgeFunction.supabase('excluir-conta');

  static const _mensagemSessao =
      'Sua sessão terminou. Entre de novo para excluir a conta.';
  static const _mensagemGenerica =
      'Não foi possível excluir a conta agora. Verifique a conexão e tente '
      'novamente.';

  final http.Client _cliente;
  final EdgeFunction _funcao;

  @override
  Future<void> excluirConta() async {
    final cabecalhos = await _funcao.cabecalhos();
    if (cabecalhos == null) {
      throw const ExclusaoContaException(_mensagemSessao);
    }

    final http.Response resposta;
    try {
      resposta = await _cliente
          .post(_funcao.url, headers: cabecalhos, body: '{}')
          .timeout(const Duration(seconds: 30));
    } on Object {
      throw const ExclusaoContaException(_mensagemGenerica);
    }

    if (resposta.statusCode == 200) return;
    if (resposta.statusCode == 401) {
      throw const ExclusaoContaException(_mensagemSessao);
    }
    throw const ExclusaoContaException(_mensagemGenerica);
  }
}
