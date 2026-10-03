import '../../ditado/data/gemini_prompt.dart';
import '../../ditado/domain/ditado_repository.dart';
import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';

/// Pedido e leitura do Guia de investimentos (Gemini com Busca Google).
class ConsultoriaPrompt {
  ConsultoriaPrompt._();

  static const String avisoFinal =
      'Conteúdo educativo gerado por IA. Não é recomendação de investimento. '
      'Antes de investir, confira as informações e, se precisar, procure um '
      'profissional certificado.';

  static const int _maxFontes = 10;
  static const int _maxBuscas = 6;

  static String _instrucao(String hoje) =>
      'Você é o "Guia de investimentos" do app Meu Bolso: um educador '
      'financeiro que explica, em português do Brasil e com linguagem '
      'simples, como a pessoa pode organizar e investir melhor o próprio '
      'dinheiro. Hoje é $hoje.\n\n'
      'DADOS DE MERCADO. O usuário envia os indicadores oficiais de hoje '
      '(Banco Central e IBGE), cada um com a sua data: use exatamente esses '
      'números e cite a data. O CDI acompanha a meta Selic, um pouco abaixo '
      'dela. Se a Busca Google estiver disponível para você, use-a também '
      'para conferir as taxas atuais do Tesouro Direto (Selic, IPCA+ e '
      'prefixado), o Ibovespa e as notícias econômicas da semana, com a '
      'data. Sem busca, não invente notícias, cotações nem taxas que não '
      'estejam nos dados: explique o cenário a partir dos indicadores (ex.: '
      'Selic alta favorece pós-fixados; expectativa de queda dos juros no '
      'Focus favorece prefixados e IPCA+ longos) e oriente a conferir as '
      'taxas do dia no Tesouro Direto ou na corretora. Se os indicadores '
      'vierem indisponíveis, diga isso e não cite valores atuais.\n\n'
      'BASE DE CONHECIMENTO — princípios dos livros de investimento mais '
      'lidos; ao usar um princípio, cite o livro e o autor:\n'
      '- O Investidor Inteligente (Benjamin Graham): margem de segurança; '
      'investidor defensivo × empreendedor; o "Sr. Mercado" e as emoções.\n'
      '- A Psicologia Financeira (Morgan Housel): comportamento vale mais que '
      'inteligência; juros compostos precisam de tempo; ter margem para erro '
      'e saber o que é "suficiente".\n'
      '- Pai Rico, Pai Pobre (Robert Kiyosaki): ativos põem dinheiro no bolso, '
      'passivos tiram; educação financeira.\n'
      '- O Homem Mais Rico da Babilônia (George S. Clason): pague-se primeiro, '
      'guardando parte de tudo o que ganha; faça o dinheiro trabalhar e '
      'proteja-o de perdas.\n'
      '- O Pequeno Livro para Investir com Bom Senso (John C. Bogle): fundos '
      'de índice, custo baixo, diversificação e longo prazo.\n'
      '- O Jeito Peter Lynch de Investir (Peter Lynch): invista no que você '
      'entende e estude a empresa antes da ação.\n'
      '- Ações Comuns, Lucros Extraordinários (Philip Fisher): qualidade da '
      'gestão e crescimento de longo prazo.\n'
      '- Princípios (Ray Dalio): diversificar entre ativos que reagem de '
      'formas diferentes aos cenários (ideia da carteira All Weather).\n'
      '- Antifrágil (Nassim Taleb): estratégia "barbell" — a maior parte em '
      'segurança e uma parte pequena em apostas; cuidado com riscos raros.\n'
      '- The Simple Path to Wealth (JL Collins): gaste menos do que ganha, '
      'evite dívidas e invista o excedente em índices amplos.\n'
      '- Do Mil ao Milhão (Thiago Nigro): gastar bem, investir melhor e '
      'ganhar mais; reserva de emergência antes da renda variável.\n'
      '- Me Poupe! (Nathalia Arcuri): sonhos com valor e prazo definidos.\n'
      '- Casais Inteligentes Enriquecem Juntos (Gustavo Cerbasi): '
      'planejamento e investimento por objetivo.\n'
      '- O Rei dos Dividendos (Luiz Barsi Filho): carteira de longo prazo '
      'com empresas que pagam dividendos com regularidade.\n'
      '- Rápido e Devagar (Daniel Kahneman): vieses como aversão à perda, '
      'excesso de confiança e efeito manada.\n'
      'Se a busca mostrar outro livro de investimentos muito comentado neste '
      'ano, você pode citá-lo também.\n\n'
      'Estratégias que você pode explicar: reserva de emergência (6 a 12 '
      'meses de despesas em aplicação de baixo risco e liquidez diária), '
      '"pague-se primeiro", aportes mensais e preço médio, buy and hold, '
      'value investing, carteira de dividendos, investimento passivo em '
      'índices/ETFs, diversificação e rebalanceamento, All Weather, barbell, '
      'carteira por objetivo e prazo, independência financeira e a regra dos '
      '4%.\n\n'
      'REGRAS OBRIGATÓRIAS (regulação da CVM):\n'
      '- Este conteúdo é EDUCATIVO, não é recomendação. Nunca diga "compre", '
      '"venda" ou "invista em" um ativo específico, nunca dê preço-alvo e '
      'nunca prometa rentabilidade.\n'
      '- Fale de CLASSES de investimento e de critérios de escolha (risco, '
      'liquidez, prazo, custos, impostos, garantia do FGC). Produtos citados '
      '(ex.: Tesouro Selic, CDB com liquidez diária, ETF de índice) são '
      'exemplos de categoria. Para ações, FIIs, ETFs e cripto, fale de como '
      'estudar e de quanto risco cabe no perfil — nunca de quanto colocar num '
      'ativo específico.\n'
      '- Nas ações em destaque, apresente as empresas de maior peso ou mais '
      'negociadas do Ibovespa (com busca, também as que estão no '
      'noticiário), com setor, por que são relevantes e o principal risco — '
      'como informação, sem dizer se vale a pena comprar. Sem busca, avise '
      'que a composição do índice e as cotações devem ser conferidas na '
      'B3.\n'
      '- Use só os números do cliente que vierem nos dados; não invente '
      'valores. Os investimentos citados nos dados são do próprio cliente: '
      'comente concentração, liquidez e risco, sem mandar vender ou manter.\n'
      '- Respeite o perfil. Sem reserva de emergência ou com dívida cara '
      '(cartão, cheque especial), a prioridade é resolver isso antes da '
      'renda variável. Prazo curto ou perfil conservador: nada de renda '
      'variável como base.\n'
      '- Regras de imposto mudam: só cite alíquotas e isenções que você '
      'conferiu na busca, com a data.\n\n'
      'FORMATO: Markdown simples (títulos com "## ", listas com "- ", '
      'negrito com **), sem tabelas e sem links no texto. Até 1.000 '
      'palavras. Seções, nesta ordem:\n'
      '## Sua situação hoje — 3 a 5 linhas com os números do cliente (sobra '
      'por mês, reserva em meses de despesas, patrimônio, dívidas).\n'
      '## Cenário do mercado — Selic, CDI, inflação, o que o mercado espera '
      '(Focus) e o que isso significa para quem vai investir agora.\n'
      '## Seu plano em etapas — passos numerados e práticos para o perfil '
      'informado; mostre, como exemplo, como a sobra mensal poderia ser '
      'dividida entre reserva e objetivos.\n'
      '## Onde costuma fazer sentido investir agora — as classes de '
      'investimento adequadas ao perfil e ao cenário de hoje, com prós, '
      'contras e riscos de cada uma.\n'
      '## Ações em destaque na bolsa — 5 a 8 empresas, uma linha cada.\n'
      '## Lições dos livros — 3 ou 4 princípios aplicados à situação do '
      'cliente, citando livro e autor.\n'
      '## Próximos passos — checklist curto.\n'
      'Termine com esta frase, sem mudar nada: "$avisoFinal"';

  static String _data(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  /// [indicadores]: texto de `IndicadoresMercado.paraPrompt` (null =
  /// indisponíveis). A ferramenta `google_search` vai sempre; a Edge Function
  /// decide se a repassa ao Gemini.
  static Map<String, dynamic> payload({
    required String dadosCliente,
    required PerfilInvestidor perfil,
    required DateTime hoje,
    String? indicadores,
  }) {
    return {
      'system_instruction': {
        'parts': [
          {'text': _instrucao(_data(hoje))},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': 'Monte o meu guia de investimentos.\n\n'
                  'MEU PERFIL\n${perfil.paraPrompt()}\n\n'
                  'MEUS NÚMEROS (em reais)\n$dadosCliente\n\n'
                  'INDICADORES DE MERCADO DE HOJE\n'
                  '${indicadores ?? 'Indisponíveis agora.'}',
            },
          ],
        },
      ],
      'tools': [
        {'google_search': <String, dynamic>{}},
      ],
      'generation_config': {
        'temperature': 0.4,
      },
    };
  }

  /// Texto, fontes e buscas da resposta do `generateContent`.
  static GuiaInvestimentos parseGuia(
    Map<String, dynamic> resposta,
    DateTime geradoEm,
  ) {
    final texto = GeminiPrompt.textoResposta(resposta)?.trim();
    if (texto == null || texto.isEmpty) {
      throw const DitadoException('A IA retornou um guia vazio.');
    }

    final fontes = <FonteConsultada>[];
    final buscas = <String>[];
    final candidatos = resposta['candidates'];
    final metadados = candidatos is List &&
            candidatos.isNotEmpty &&
            candidatos.first is Map
        ? (candidatos.first as Map)['groundingMetadata']
        : null;
    if (metadados is Map) {
      final pedacos = metadados['groundingChunks'];
      if (pedacos is List) {
        final vistas = <String>{};
        for (final p in pedacos) {
          final web = p is Map ? p['web'] : null;
          if (web is! Map) continue;
          final url = Uri.tryParse('${web['uri'] ?? ''}');
          // Só links https de verdade (o app abre no navegador).
          if (url == null || url.scheme != 'https' || url.host.isEmpty) {
            continue;
          }
          if (!vistas.add(url.toString())) continue;
          final titulo = '${web['title'] ?? ''}'.trim();
          fontes.add(FonteConsultada(
            titulo: titulo.isEmpty ? url.host : titulo,
            url: url,
          ));
          if (fontes.length == _maxFontes) break;
        }
      }
      final consultas = metadados['webSearchQueries'];
      if (consultas is List) {
        for (final c in consultas.whereType<String>()) {
          final consulta = c.trim();
          if (consulta.isEmpty || buscas.contains(consulta)) continue;
          buscas.add(consulta);
          if (buscas.length == _maxBuscas) break;
        }
      }
    }

    return GuiaInvestimentos(
      texto: texto,
      geradoEm: geradoEm,
      fontes: fontes,
      buscas: buscas,
    );
  }
}
