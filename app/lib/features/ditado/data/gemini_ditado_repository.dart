import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';
import 'gemini_cliente.dart';
import 'gemini_prompt.dart';

/// Ditado, correção de campo e análise do mês pelo Gemini (via [GeminiCliente],
/// que fala com a Edge Function `ditado`).
class GeminiDitadoRepository implements DitadoRepository {
  GeminiDitadoRepository({
    http.Client? cliente,
    EdgeFunction? funcao,
    String? modelo,
    List<Duration>? esperasRetry,
    List<String> Function()? formasPagamento,
  })  : _lerFormasPagamento = formasPagamento,
        _gemini = GeminiCliente(
          cliente: cliente,
          funcao: funcao,
          modelo: modelo,
          esperasRetry: esperasRetry,
        );

  final GeminiCliente _gemini;

  /// Formas de pagamento do usuário (dependem dos cartões dele), lidas na hora
  /// de cada pedido.
  final List<String> Function()? _lerFormasPagamento;

  Future<Map<String, dynamic>> _post(Map<String, dynamic> corpo) =>
      _gemini.gerar(corpo);

  @override
  Future<RascunhoLancamento> reconhecer(LancamentoAudio audio) async {
    final resposta = await _post(
      GeminiPrompt.payloadReconhecer(audio, formas: _lerFormasPagamento?.call()),
    );
    final texto = GeminiPrompt.textoResposta(resposta);
    if (texto == null) {
      throw const DitadoException('A IA retornou uma resposta vazia.');
    }
    return GeminiPrompt.parseRascunho(texto);
  }

  @override
  Future<String?> corrigirCampo(
    CampoDitado campo, {
    LancamentoAudio? audio,
    String? texto,
    RascunhoLancamento? rascunhoAtual,
  }) async {
    final resposta = await _post(
      GeminiPrompt.payloadCorrigir(
        campo,
        audio: audio,
        texto: texto,
        rascunhoAtual: rascunhoAtual,
        formas: _lerFormasPagamento?.call(),
      ),
    );
    final corpo = GeminiPrompt.textoResposta(resposta);
    if (corpo == null) {
      throw const DitadoException('A IA retornou uma resposta vazia.');
    }
    return GeminiPrompt.parseCorrecao(corpo, campo);
  }

  @override
  Future<String> gerarAnaliseMensal(
    String dadosDoMes,
    String mesAnoLabel,
  ) async {
    final resposta = await _post(
      GeminiPrompt.payloadAnaliseMensal(dadosDoMes, mesAnoLabel),
    );
    final texto = GeminiPrompt.textoResposta(resposta);
    if (texto == null || texto.trim().isEmpty) {
      throw const DitadoException('A IA retornou um diagnóstico vazio.');
    }
    return texto.trim();
  }
}
