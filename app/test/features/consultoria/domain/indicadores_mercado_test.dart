import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/consultoria/domain/indicadores_mercado.dart';

/// Resposta real da Edge Function `indicadores` (03/10/2026).
const _json = {
  'consultadoEm': '2026-10-03T18:40:00.000Z',
  'selic': {'meta': 13.75, 'reuniao': '2026-09-16', 'anterior': 14.0},
  'focus': {
    'data': '2026-09-25',
    'selic': [
      {'ano': 2026, 'mediana': 13.5},
      {'ano': 2027, 'mediana': 12.0},
    ],
    'ipca': [
      {'ano': 2026, 'mediana': 4.9915},
      {'ano': 2027, 'mediana': 4.3118},
    ],
  },
  'ipca12m': {'valor': 4.22, 'referencia': 'agosto 2026'},
  'dolar': {'venda': 5.2238, 'data': '2026-10-02'},
};

void main() {
  test('lê a resposta da função e escreve o texto do prompt com as datas', () {
    final i = IndicadoresMercado.fromJson(_json);
    final texto = i.paraPrompt();

    expect(i.vazio, isFalse);
    expect(texto, contains('Consultados em 03/10/2026'));
    expect(
      texto,
      contains('Meta da taxa Selic: 13,75% ao ano, definida pelo Copom em '
          '16/09/2026 (antes: 14,00%)'),
    );
    expect(texto, contains('IPCA acumulado em 12 meses: 4,22% (até agosto 2026)'));
    expect(texto, contains('boletim Focus de 25/09/2026'));
    expect(texto, contains('Selic no fim de 2026: 13,50%'));
    expect(texto, contains('IPCA no fim de 2027: 4,31%'));
    expect(texto, contains('Dólar (PTAX, venda): R\$ 5,22 em 02/10/2026'));
    expect(i.fontes.map((f) => f.url.host).toSet(),
        {'www.bcb.gov.br', 'sidra.ibge.gov.br'});
    expect(i.fontes, hasLength(4));
  });

  test('indicador que faltou não aparece (nem a fonte dele)', () {
    final i = IndicadoresMercado.fromJson({
      'consultadoEm': '2026-10-03T18:40:00.000Z',
      'selic': {'meta': 13.75, 'reuniao': '2026-09-16', 'anterior': 13.75},
      'focus': null,
      'ipca12m': null,
      'dolar': null,
    });
    final texto = i.paraPrompt();
    expect(texto, contains('13,75% ao ano'));
    expect(texto, isNot(contains('antes:'))); // meta não mudou
    expect(texto, isNot(contains('Focus')));
    expect(texto, isNot(contains('Dólar')));
    expect(i.fontes, hasLength(1));
  });

  test('tudo fora do ar: vazio', () {
    final i = IndicadoresMercado.fromJson({'selic': null});
    expect(i.vazio, isTrue);
    expect(i.paraPrompt(), contains('Indisponíveis'));
    expect(i.fontes, isEmpty);
  });
}
