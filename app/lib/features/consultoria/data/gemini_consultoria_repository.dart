import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../../ditado/data/gemini_cliente.dart';
import '../../ditado/data/gemini_prompt.dart';
import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';
import 'consultoria_prompt.dart';

/// Guia de investimentos pelo Gemini com Busca Google, via Edge Function
/// `ditado` (que só aceita a ferramenta `google_search` e tem cota própria
/// para esses pedidos).
class GeminiConsultoriaRepository implements ConsultoriaRepository {
  GeminiConsultoriaRepository({
    http.Client? cliente,
    EdgeFunction? funcao,
    List<Duration>? esperasRetry,
    DateTime Function()? relogio,
  })  : _gemini = GeminiCliente(
          cliente: cliente,
          funcao: funcao,
          esperasRetry: esperasRetry,
        ),
        _relogio = relogio ?? DateTime.now;

  /// Pesquisa + texto longo pode levar quase um minuto: poucos modelos e
  /// poucas tentativas, para o cliente não esperar demais quando a IA cai.
  static const List<String> modelos = [GeminiPrompt.modelo, 'gemini-2.5-flash'];
  static const int tentativasPorModelo = 2;

  final GeminiCliente _gemini;
  final DateTime Function() _relogio;

  @override
  Future<GuiaInvestimentos> gerar({
    required String dadosCliente,
    required PerfilInvestidor perfil,
  }) async {
    final agora = _relogio();
    final resposta = await _gemini.gerar(
      ConsultoriaPrompt.payload(
        dadosCliente: dadosCliente,
        perfil: perfil,
        hoje: agora,
      ),
      modelos: modelos,
      tentativas: tentativasPorModelo,
    );
    return ConsultoriaPrompt.parseGuia(resposta, agora);
  }
}
