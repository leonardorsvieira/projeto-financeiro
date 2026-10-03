import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../../ditado/data/gemini_cliente.dart';
import '../../ditado/data/gemini_prompt.dart';
import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';
import 'consultoria_prompt.dart';

/// Guia de investimentos pelo Gemini, via Edge Function `ditado` (cota própria
/// para o guia). O pedido leva a ferramenta `google_search`, mas a função só a
/// repassa com o segredo BUSCA_GOOGLE=1 (no plano gratuito a busca não existe
/// para os modelos 3.x); sem ela, o guia usa os indicadores do Banco Central.
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
  static const List<String> modelos = [GeminiPrompt.modelo, 'gemini-3.5-flash'];
  static const int tentativasPorModelo = 2;

  final GeminiCliente _gemini;
  final DateTime Function() _relogio;

  @override
  Future<GuiaInvestimentos> gerar({
    required String dadosCliente,
    required PerfilInvestidor perfil,
    String? indicadores,
  }) async {
    final agora = _relogio();
    final resposta = await _gemini.gerar(
      ConsultoriaPrompt.payload(
        dadosCliente: dadosCliente,
        perfil: perfil,
        indicadores: indicadores,
        hoje: agora,
      ),
      modelos: modelos,
      tentativas: tentativasPorModelo,
    );
    return ConsultoriaPrompt.parseGuia(resposta, agora);
  }
}
