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
    List<Duration>? esperasRetry,
  })  : _cliente = cliente ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _modelo = modelo ?? GeminiPrompt.modelo,
        _esperasRetry =
            esperasRetry ??
            const [
              Duration(milliseconds: 800),
              Duration(milliseconds: 1600),
            ];

  static const String _baseUrl = 'generativelanguage.googleapis.com';
  static const String _caminho = '/v1beta/models/';
  static const int _maxTentativas = 3;
  static const Set<int> _errosTemporarios = {429, 500, 502, 503};

  final http.Client _cliente;
  final String _apiKey;
  final String _modelo;
  final List<Duration> _esperasRetry;

  Future<Map<String, dynamic>> _post(Map<String, dynamic> corpo) async {
    if (_apiKey.isEmpty) {
      throw const DitadoException(
        'IA não configurada. Adicione a GEMINI_API_KEY no deploy.',
      );
    }
    for (var tentativa = 0; tentativa < _maxTentativas; tentativa++) {
      if (tentativa > 0 && tentativa - 1 < _esperasRetry.length) {
        await Future<void>.delayed(_esperasRetry[tentativa - 1]);
      }
      final uri = Uri.https(
        _baseUrl,
        '$_caminho$_modelo:generateContent',
        {'key': _apiKey},
      );
      final resposta = await _cliente.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(corpo),
      );
      if (resposta.statusCode == 200) {
        final decodificado = jsonDecode(resposta.body);
        if (decodificado is! Map<String, dynamic>) {
          throw const DitadoException(
            'A resposta da IA veio em um formato inesperado.',
          );
        }
        return decodificado;
      }
      final ultimaTentativa = tentativa == _maxTentativas - 1;
      if (!ultimaTentativa &&
          _errosTemporarios.contains(resposta.statusCode)) {
        continue;
      }
      throw DitadoException(
        'IA indisponível no momento (HTTP ${resposta.statusCode}). '
        'Tente de novo.',
      );
    }
    throw const DitadoException('IA indisponível no momento. Tente de novo.');
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