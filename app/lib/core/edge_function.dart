import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Mensagem para conta sem assinatura ativa (403 `acesso_inativo` das funções).
const mensagemAcessoInativo =
    'Seu acesso não está ativo. Para continuar usando o Meu Bolso, fale com o vendedor.';

/// A Edge Function recusou a chamada porque a conta não tem acesso ativo.
/// Confere o CORPO: o 403 de `rota_nao_permitida` é outro erro.
bool ehAcessoInativo(int status, String corpo) =>
    status == 403 && corpo.contains('acesso_inativo');

/// Endereço e credenciais para chamar uma Supabase Edge Function.
///
/// Chaves de serviços externos (Gemini, Pluggy) ficam só nas Edge Functions:
/// tudo que entra via `--dart-define` acaba no bundle web público.
class EdgeFunction {
  const EdgeFunction({
    required this.url,
    required this.anonKey,
    required this.tokenDeAcesso,
  });

  factory EdgeFunction.supabase(String nome) => EdgeFunction(
        url: Uri.parse('${AppEnv.supabaseUrl}/functions/v1/$nome'),
        anonKey: AppEnv.supabaseAnonKey,
        tokenDeAcesso: _tokenDaSessao,
      );

  final Uri url;
  final String anonKey;
  final Future<String?> Function() tokenDeAcesso;

  static Future<String?> _tokenDaSessao() async {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } on Object {
      return null;
    }
  }

  /// Cabeçalhos da chamada, ou null se não houver usuário logado.
  Future<Map<String, String>?> cabecalhos() async {
    final token = await tokenDeAcesso();
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'apikey': anonKey,
      'Content-Type': 'application/json',
    };
  }
}
