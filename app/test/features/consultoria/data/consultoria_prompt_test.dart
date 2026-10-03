import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/consultoria/data/consultoria_prompt.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';

void main() {
  const perfil = PerfilInvestidor(
    objetivo: ObjetivoInvestimento.aposentadoria,
    prazo: PrazoInvestimento.longo,
    risco: ToleranciaRisco.moderado,
    observacao: 'Tenho 30 anos',
  );

  group('payload', () {
    final payload = ConsultoriaPrompt.payload(
      dadosCliente: 'Sobra: R\$ 1.500,00 por mês',
      perfil: perfil,
      hoje: DateTime(2026, 10, 3),
    );
    final sistema = ((payload['system_instruction'] as Map)['parts'] as List)
        .first['text']
        .toString();
    final usuario =
        (((payload['contents'] as List).first as Map)['parts'] as List)
            .first['text']
            .toString();

    test('usa só a Busca Google como ferramenta', () {
      expect(payload['tools'], [
        {'google_search': <String, dynamic>{}},
      ]);
    });

    test('pesquisa o mercado de hoje e traz os livros', () {
      expect(sistema, contains('Hoje é 03/10/2026'));
      expect(sistema, contains('Selic'));
      expect(sistema, contains('IPCA'));
      expect(sistema, contains('O Investidor Inteligente (Benjamin Graham)'));
      expect(sistema, contains('A Psicologia Financeira (Morgan Housel)'));
      expect(sistema, contains('## Ações em destaque na bolsa'));
    });

    test('é educativo: sem recomendação de compra e com aviso final', () {
      expect(sistema, contains('não é recomendação'));
      expect(sistema, contains('Nunca diga "compre"'));
      expect(sistema, contains('nunca dê preço-alvo'));
      expect(sistema, contains(ConsultoriaPrompt.avisoFinal));
    });

    test('manda o perfil e os números do cliente', () {
      expect(usuario, contains('Aposentadoria / independência financeira'));
      expect(usuario, contains('Mais de 5 anos'));
      expect(usuario, contains('Moderado'));
      expect(usuario, contains('"Tenho 30 anos"'));
      expect(usuario, contains('Sobra: R\$ 1.500,00 por mês'));
    });
  });

  group('indicadores de mercado', () {
    String usuarioDe(Map<String, dynamic> p) =>
        (((p['contents'] as List).first as Map)['parts'] as List)
            .first['text']
            .toString();
    String sistemaDe(Map<String, dynamic> p) =>
        ((p['system_instruction'] as Map)['parts'] as List)
            .first['text']
            .toString();

    test('vão no pedido; sem eles, o pedido avisa que estão indisponíveis',
        () {
      final com = ConsultoriaPrompt.payload(
        dadosCliente: '',
        perfil: perfil,
        hoje: DateTime(2026, 10, 3),
        indicadores: '- Meta da taxa Selic: 13,75% ao ano',
      );
      expect(usuarioDe(com), contains('INDICADORES DE MERCADO DE HOJE\n'
          '- Meta da taxa Selic: 13,75% ao ano'));

      final sem = ConsultoriaPrompt.payload(
        dadosCliente: '',
        perfil: perfil,
        hoje: DateTime(2026, 10, 3),
      );
      expect(usuarioDe(sem), contains('Indisponíveis agora.'));
    });

    test('sem busca, a IA não inventa dados de hoje', () {
      final sistema = sistemaDe(ConsultoriaPrompt.payload(
        dadosCliente: '',
        perfil: perfil,
        hoje: DateTime(2026, 10, 3),
      ));
      expect(sistema, contains('use exatamente esses números'));
      expect(sistema, contains('Sem busca, não invente notícias'));
      expect(sistema, contains('não cite valores atuais'));
    });
  });

  test('observação longa é cortada no limite', () {
    final longa = 'a' * 500;
    final texto = const PerfilInvestidor().copyWith(observacao: longa).paraPrompt();
    expect(texto, contains('"${'a' * PerfilInvestidor.maxObservacao}"'));
    expect(texto, isNot(contains('a' * (PerfilInvestidor.maxObservacao + 1))));
  });

  group('parseGuia', () {
    final geradoEm = DateTime(2026, 10, 3, 14, 30);

    test('texto, fontes https sem repetição e buscas', () {
      final guia = ConsultoriaPrompt.parseGuia({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '## Sua situação hoje\nTudo certo.'},
              ],
            },
            'groundingMetadata': {
              'webSearchQueries': ['taxa selic hoje', 'ipca 12 meses', ''],
              'groundingChunks': [
                {
                  'web': {
                    'uri': 'https://vertexaisearch.cloud.google.com/a',
                    'title': 'bcb.gov.br',
                  },
                },
                {
                  'web': {
                    'uri': 'https://vertexaisearch.cloud.google.com/a',
                    'title': 'bcb.gov.br',
                  },
                },
                {
                  'web': {'uri': 'javascript:alert(1)', 'title': 'x'},
                },
                {
                  'web': {'uri': 'https://exemplo.com.br/b', 'title': ''},
                },
              ],
            },
          },
        ],
      }, geradoEm);

      expect(guia.texto, '## Sua situação hoje\nTudo certo.');
      expect(guia.geradoEm, geradoEm);
      expect(guia.fontes.map((f) => f.titulo), ['bcb.gov.br', 'exemplo.com.br']);
      expect(guia.buscas, ['taxa selic hoje', 'ipca 12 meses']);
    });

    test('sem metadados de busca ainda devolve o texto', () {
      final guia = ConsultoriaPrompt.parseGuia({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Guia'},
              ],
            },
          },
        ],
      }, geradoEm);
      expect(guia.texto, 'Guia');
      expect(guia.fontes, isEmpty);
      expect(guia.buscas, isEmpty);
    });

    test('resposta vazia vira erro', () {
      expect(
        () => ConsultoriaPrompt.parseGuia({'candidates': []}, geradoEm),
        throwsA(isA<DitadoException>()),
      );
    });
  });
}
