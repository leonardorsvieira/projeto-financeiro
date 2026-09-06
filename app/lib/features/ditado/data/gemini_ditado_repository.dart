import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';
import 'gemini_prompt.dart';

class GeminiDitadoRepository implements DitadoRepository {
  GeminiDitadoRepository({
    http.Client? cliente,
    String? apiKey,
    String? modelo,
  })  : _cliente = cliente ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _modelo = modelo ?? GeminiPrompt.modelo;

  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _caminho = '/v1beta/models/';

  final http.Client _cliente;
  final String _apiKey;
  final String _modelo;

  Future<Map<String, dynamic>> _post(Map<String, dynamic> corpo) async {
    if (_apiKey.isEmpty) {
      throw const DitadoException(
        'IA não configurada. Adicione a GEMINI_API_KEY no deploy.',
      );
    }
    final uri =
        Uri.https(_baseUrl, '$_caminho$_modelo:generateContent', {'key': _apiKey});
    final resposta = await _cliente.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(corpo),
    );
    if (resposta.statusCode != 200) {
      throw DitadoException(
        'IA indisponível no momento (HTTP ${resposta.statusCode}).',
      );
    }
    final decodificado = jsonDecode(resposta.body);
    if (decodificado is! Map<String, dynamic>) {
      throw const DitadoException('A resposta da IA veio em um formato inesperado.');
    }
    return decodificado;
  }

  @override
  Future<RascunhoLancamento> reconhecer(LancamentoAudio audio) async {
    final resposta = await _post(GeminiPrompt.payloadReconhecer(audio));
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
      ),
    );
    final corpo = GeminiPrompt.textoResposta(resposta);
    if (corpo == null) {
      throw const DitadoException('A IA retornou uma resposta vazia.');
    }
    return GeminiPrompt.parseCorrecao(corpo, campo);
  }
}