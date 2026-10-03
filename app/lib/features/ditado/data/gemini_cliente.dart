import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/edge_function.dart';
import '../domain/ditado_repository.dart';
import 'gemini_prompt.dart';

/// Chama o Gemini através da Edge Function `ditado` (a GEMINI_API_KEY fica só
/// no servidor). Cada tentativa envia `{modelo, corpo}`; a função valida o
/// usuário, aplica a cota diária e repassa o `generateContent`. Erro
/// temporário é repetido; se o modelo não responder, tenta o próximo.
class GeminiCliente {
  GeminiCliente({
    http.Client? cliente,
    EdgeFunction? funcao,
    String? modelo,
    List<Duration>? esperasRetry,
  })  : _cliente = cliente ?? http.Client(),
        _funcao = funcao ?? EdgeFunction.supabase('ditado'),
        _modelo = modelo ?? GeminiPrompt.modelo,
        _esperasRetry =
            esperasRetry ??
            const [
              Duration(milliseconds: 800),
              Duration(milliseconds: 1600),
            ];

  static const int _maxTentativas = 3;
  static const Set<int> _errosTemporarios = {429, 500, 502, 503};

  final http.Client _cliente;
  final EdgeFunction _funcao;
  final String _modelo;
  final List<Duration> _esperasRetry;

  /// Reservas quando o modelo padrão falha. Os 2.x não servem mais (o Google
  /// restringiu o 2.5 a quem já o usava; 2.0/1.5 saíram do ar). Mantenha em
  /// sincronia com MODELOS_PERMITIDOS da Edge Function `ditado`.
  static const List<String> _modelosCandidatos = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash-lite',
  ];

  /// Resposta do `generateContent`. [modelos] troca a lista de fallback
  /// (padrão: o modelo configurado e depois os candidatos); [tentativas] é o
  /// máximo de tentativas por modelo.
  Future<Map<String, dynamic>> gerar(
    Map<String, dynamic> corpo, {
    List<String>? modelos,
    int tentativas = _maxTentativas,
  }) async {
    final cabecalhos = await _funcao.cabecalhos();
    if (cabecalhos == null) {
      throw const DitadoException('Entre na sua conta para usar a IA.');
    }

    Object? ultimoErro;
    final modelosTestar = modelos ??
        <String>[
          _modelo,
          ..._modelosCandidatos.where((m) => m != _modelo),
        ];

    for (final mod in modelosTestar) {
      for (var tentativa = 0; tentativa < tentativas; tentativa++) {
        if (tentativa > 0 && tentativa - 1 < _esperasRetry.length) {
          await Future<void>.delayed(_esperasRetry[tentativa - 1]);
        }
        final http.Response resposta;
        try {
          resposta = await _cliente.post(
            _funcao.url,
            headers: cabecalhos,
            body: jsonEncode({'modelo': mod, 'corpo': corpo}),
          );
        } catch (e) {
          ultimoErro = e;
          continue;
        }
        _falhaDefinitiva(resposta);
        if (resposta.statusCode == 200) {
          final decodificado = jsonDecode(resposta.body);
          if (decodificado is! Map<String, dynamic>) {
            throw const DitadoException(
              'A resposta da IA veio em um formato inesperado.',
            );
          }
          return decodificado;
        }
        ultimoErro = 'HTTP ${resposta.statusCode}';
        final ultimaTentativa = tentativa == tentativas - 1;
        if (ultimaTentativa ||
            !_errosTemporarios.contains(resposta.statusCode)) {
          break;
        }
      }
    }

    throw DitadoException(
      'IA indisponível no momento ($ultimoErro). Tente de novo.',
    );
  }

  /// Erros da própria Edge Function: não adianta repetir nem trocar de modelo.
  static void _falhaDefinitiva(http.Response resposta) {
    final corpo = resposta.body;
    if (ehAcessoInativo(resposta.statusCode, corpo)) {
      throw const DitadoException(mensagemAcessoInativo);
    }
    if (resposta.statusCode == 401) {
      throw const DitadoException(
        'Sessão expirada ou e-mail não confirmado. Entre de novo.',
      );
    }
    if (resposta.statusCode == 429 &&
        corpo.contains('limite_diario_consultoria')) {
      throw const DitadoException(
        'Você já gerou o máximo de guias de investimento de hoje. '
        'Tente amanhã.',
      );
    }
    if (resposta.statusCode == 429 && corpo.contains('limite_diario')) {
      throw const DitadoException(
        'Você atingiu o limite diário de uso da IA. Tente amanhã.',
      );
    }
    if (resposta.statusCode == 503 && corpo.contains('ia_nao_configurada')) {
      throw const DitadoException('IA não configurada no servidor.');
    }
  }
}
