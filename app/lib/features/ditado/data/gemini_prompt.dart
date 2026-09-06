import 'dart:convert';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';

class GeminiPrompt {
  GeminiPrompt._();

  static const String modelo = 'gemini-3.5-flash';

  static final String _instrucaoReconhecer =
      'Você é o assistente financeiro do aplicativo "Meu Bolso". '
      'O usuário dita um gasto em português do Brasil.\n\n'
      'Transcreva o áudio e devolva APENAS um JSON válido — sem texto fora '
      'do JSON — no formato exato:\n'
      '{"descricao": string|null, "valor_reais": string|null, '
      '"categoria": string|null, "forma_pagamento": string|null, '
      '"data": "AAAA-MM-DD"|null, "vencimento": "AAAA-MM-DD"|null}\n\n'
      'Regras:\n'
      '- valor_reais deve ser uma string numérica com vírgula como separador '
      'decimal e sem cifrão (ex.: "42,90"). Resolva números falados por '
      'extenso (ex.: "quarenta e dois e noventa" -> "42,90").\n'
      '- categoria deve ser escolhida APENAS entre: ${categorias.join(', ')}.\n'
      '- forma_pagamento deve ser escolhida APENAS entre: '
      '${formasPagamento.join(', ')}.\n'
      '- Se o usuário não citar um campo, deixe null. NÃO invente '
      'valores, categorias ou formas.\n'
      '- data: apenas se o usuário citar o dia; senão null (o app usa hoje '
      'como padrão). Hoje é {hoje}.\n'
      '- vencimento: apenas se citado; senão null.';

  static final String _instrucaoCorrecao =
      'Você receberá um áudio (ou texto) com a correção de UM campo de um '
      'lançamento financeiro do aplicativo "Meu Bolso".\n'
      'Devolva APENAS um JSON válido — sem texto fora do JSON — no formato '
      'exato: {"{campo}": valor|null}\n'
      'Regras por campo:\n'
      '- descricao: string (ex.: {"descricao": "Almoço"}).\n'
      '- valor: string numérica com vírgula decimal (ex.: {"valor": "39,90"});'
      ' resolva números por extenso.\n'
      '- categoria: escolha APENAS entre '
      '${categorias.join(', ')} (ex.: {"categoria": "Alimentação"}).\n'
      '- forma_pagamento: escolha APENAS entre '
      '${formasPagamento.join(', ')}.\n'
      '- data e vencimento: "AAAA-MM-DD" (ex.: {"data": "2026-09-06"}).\n'
      'Se a correção não trouxer valor para o campo, use null. Hoje é {hoje}.';

  static String _instrucao(String base, {required String campo}) {
    return base
        .replaceAll('{hoje}', _dataHoje())
        .replaceAll('{campo}', campo);
  }

  static String _dataHoje() {
    final agora = DateTime.now();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${agora.year}-${dois(agora.month)}-${dois(agora.day)}';
  }

  static Map<String, dynamic> payloadReconhecer(LancamentoAudio audio) {
    return {
      'system_instruction': {
        'parts': [
          {'text': _instrucao(_instrucaoReconhecer, campo: '')},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Preencha o lançamento ditado no áudio.'},
            {
              'inline_data': {
                'mime_type': audio.mimeType,
                'data': base64Encode(audio.bytes),
              },
            },
          ],
        },
      ],
      'generation_config': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      },
    };
  }

  static Map<String, dynamic> payloadCorrigir(
    CampoDitado campo, {
    LancamentoAudio? audio,
    String? texto,
    RascunhoLancamento? rascunhoAtual,
  }) {
    final partes = <Map<String, dynamic>>[
      {
        'text': 'Rascunho atual: ${rascunhoAtual?.toJson() ?? '{}'}\n'
            'Corrija o campo "${campo.chaveJson}" a partir da informação '
            'fornecida e retorne apenas esse campo.',
      },
    ];
    if (audio != null) {
      partes.add({
        'inline_data': {
          'mime_type': audio.mimeType,
          'data': base64Encode(audio.bytes),
        },
      });
    } else if (texto != null && texto.trim().isNotEmpty) {
      partes.add({'text': texto.trim()});
    }

    return {
      'system_instruction': {
        'parts': [
          {'text': _instrucao(_instrucaoCorrecao, campo: campo.chaveJson)},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': partes,
        },
      ],
      'generation_config': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      },
    };
  }

  static String? textoResposta(Map<String, dynamic> resposta) {
    final candidatos = resposta['candidates'];
    if (candidatos is! List || candidatos.isEmpty) return null;
    final primeiro = candidatos.first;
    if (primeiro is! Map<String, dynamic>) return null;
    final conteudo = primeiro['content'];
    if (conteudo is! Map<String, dynamic>) return null;
    final partes = conteudo['parts'];
    if (partes is! List) return null;
    final textos = partes
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'])
        .whereType<String>()
        .join('');
    return textos.isEmpty ? null : textos;
  }

  static Map<String, dynamic> extraiJson(String texto) {
    final inicio = texto.indexOf('{');
    final fim = texto.lastIndexOf('}');
    if (inicio < 0 || fim < inicio) {
      throw const DitadoException('A IA não retornou um JSON válido.');
    }
    final decodificado = jsonDecode(texto.substring(inicio, fim + 1));
    if (decodificado is! Map<String, dynamic>) {
      throw const DitadoException('A IA não retornou um objeto JSON.');
    }
    return decodificado;
  }

  static RascunhoLancamento parseRascunho(String texto) {
    return RascunhoLancamento.fromJson(extraiJson(texto));
  }

  static String? parseCorrecao(String texto, CampoDitado campo) {
    final json = extraiJson(texto);
    final v = json[campo.chaveJson];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}