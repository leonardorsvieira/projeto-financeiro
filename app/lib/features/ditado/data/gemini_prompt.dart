import 'dart:convert';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';
import '../domain/rascunho_investimento.dart';

class GeminiPrompt {
  GeminiPrompt._();

  static const String modelo = 'gemini-3.5-flash-lite';

  static final String _instrucaoReconhecer =
      'Você é o assistente financeiro do aplicativo "Meu Bolso". '
      'O usuário dita um lançamento em português do Brasil — um gasto, um '
      'recebimento OU um investimento.\n\n'
      'Transcreva o áudio e devolva APENAS um JSON válido — sem texto fora '
      'do JSON — no formato exato:\n'
      '{"descricao": string|null, "valor_reais": string|null, '
      '"categoria": string|null, "forma_pagamento": string|null, '
      '"data": "AAAA-MM-DD"|null, "vencimento": "AAAA-MM-DD"|null, '
      '"tipo": "despesa"|"receita"|"investimento"|null, '
      '"itens": [{"descricao": string, "valor_reais": string|null}]|null, '
      '"investimento_classe": "acao"|"fii"|"cripto"|"renda_fixa"|"banco_digital"|null, '
      '"investimento_nome": string|null, '
      '"operacao": "compra"|"venda"|"aporte"|"resgate"|"dividendo"|"juros"|"rendimento"|null, '
      '"quantidade": string|null, '
      '"preco_unitario": string|null, '
      '"valor": string|null}\n\n'
      'Regras:\n'
      '- valor_reais deve ser uma string numérica com vírgula como separador '
      'decimal e sem cifrão (ex.: "42,90"). Resolva números falados por '
      'extenso (ex.: "quarenta e dois e noventa" -> "42,90").\n'
      '- tipo: "receita" quando o usuário receber dinheiro (ex.: "recebi", '
      '"ganhei", "solicitei", "salário", "depósito recebido", "transferência '
      'recebida", "devolução", "pagamento recebido"). "despesa" quando pagar '
      'ou gastar (ex.: "gastei", "paguei", "comprei", "fatura", "conta de", '
      '"transferi"). "investimento" quando houver sinais de compra/venda/aporte/'
      'resgate/dividendos de ativos (ex.: "comprei 10 PETR4 a 38,50", "aportei '
      '500 no CDB", "vendi 5 BBSE3", "resgatei 1000 do Nubank", "recebi '
      'dividendos da TAEE11", "rendimento de 50 do Tesouro"). Se não houver '
      'sinal claro de investimento, use "despesa".\n'
      '- Se tipo="investimento", os campos a seguir SÃO OBRIGATÓRIOS:\n'
      '  * investimento_classe: escolha APENAS entre acao, fii, cripto, '
      'renda_fixa, banco_digital.\n'
      '  * investimento_nome: nome do ativo (ex.: PETR4, CDB, Nubank, Bitcoin).\n'
      '  * operacao: compra|venda (para acao/fii/cripto) OU aporte|resgate '
      '(para renda_fixa/banco_digital) OU dividendo|juros|rendimento '
      '(para proventos).\n'
      '  * Para compra/venda: quantidade (ex.: "10") + preco_unitario '
      '(ex.: "38,50").\n'
      '  * Para aporte/resgate: valor (ex.: "500,00").\n'
      '  * Para dividendo/juros/rendimento: valor (ex.: "120,00").\n'
      '  * data: apenas se citada; senão null.\n'
      '- categoria deve ser escolhida APENAS entre: ${categorias.join(', ')}.\n'
      '- forma_pagamento deve ser escolhida APENAS entre: '
      '${formasPagamento.join(', ')}.\n'
      '- categoria e forma_pagamento DEVEM ser exatamente uma das opções '
      'listadas (mesmo texto). Se houver dúvida ou nenhuma opção encaixar, '
      'use "Outros" para categoria e "Outro" para forma de pagamento. Nunca '
      'invente ou adapte os nomes.\n'
      '- Exemplos de mapeamento: restaurante/almoço/lanche/iFood = '
      'Alimentação; uber/táxi/gasolina/ônibus = Transporte; aluguel/condomínio/'
      'conta de luz, água ou gás/IPTU = Moradia; supermercado/feira/padaria = '
      'Mercado; academia/plano de saúde/farmácia = Saúde; streaming/plano de '
      'celular/internet = Assinaturas; cinema/bares/viagem = Lazer; curso/'
      'livros/faculdade = Educação.\n'
      '- Se o usuário não citar um campo, deixe null. NÃO invente '
      'valores, categorias ou formas.\n'
      '- data: apenas se o usuário citar o dia; senão null (o app usa hoje '
      'como padrão). Não preencha data só porque conhece o dia de hoje. '
      'Hoje é {hoje}.\n'
      '- vencimento: apenas se citado; senão null. Apenas para despesas '
      '(recebimentos não têm vencimento). Se o usuário ditar apenas '
      'o dia (ex.: "vence dia 15"), interprete como o próximo mês com esse dia. '
      'Ex.: hoje {hoje} -> "vence dia 15" = próximo dia 15.\n'
      '- itens: opcional. Se o usuário ditar uma lista (ex.: "comprei arroz 20, '
      'feijão 12, carne 45"), extraia cada item com descricao e valor_reais. '
      'valor_reais do item pode ser null se não citado. O valor total do '
      'lançamento será a soma dos itens (se houver itens) ou o valor_reais raiz.';

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
      '${categorias.join(', ')}; em dúvida, use "Outros". Nunca invente '
      '(ex.: {"categoria": "Alimentação"}).\n'
      '- forma_pagamento: escolha APENAS entre '
      '${formasPagamento.join(', ')}; em dúvida, use "Outro".\n'
      '- data e vencimento: "AAAA-MM-DD" apenas se citada a data; senão null '
      '(não use hoje se não foi falado). Hoje é {hoje}.\n'
      '- tipo: exatamente "despesa" ou "receita", conforme o usuário descrever '
      'o lançamento (ex.: {"tipo": "receita"}).\n'
      '- itens: array completo de itens no formato '
      '[{"descricao": string, "valor_reais": string|null}] (ex.: '
      '{"itens": [{"descricao": "Arroz", "valor_reais": "20,00"}, '
      '{"descricao": "Feijão", "valor_reais": "12,00"}]}).';

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

  static Map<String, dynamic> payloadAnaliseMensal(
    dynamic resumo,
    dynamic gastos,
    String mesAnoLabel,
  ) {
    return {
      'system_instruction': {
        'parts': [
          {
            'text':
                'Você é um consultor financeiro pessoal amigável do app "Meu Bolso". '
                    'Analise os dados financeiros do usuário do mês de $mesAnoLabel e forneça '
                    'um diagnóstico curto em português (3 parágrafos pequenos), com tom positivo e direto, '
                    'destacando o saldo do mês, as maiores categorias de gasto e 1 dica prática de economia.'
          },
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': 'Dados do mês ($mesAnoLabel):\n'
                  'Resumo do Mês: $resumo\n'
                  'Gastos por Categoria: $gastos'
            },
          ],
        },
      ],
      'generation_config': {
        'temperature': 0.3,
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

  static RascunhoInvestimento parseRascunhoInvestimento(String texto) {
    return RascunhoInvestimento.fromJson(extraiJson(texto));
  }

  static String? parseCorrecao(String texto, CampoDitado campo) {
    final json = extraiJson(texto);
    final v = json[campo.chaveJson];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}