import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/consultoria/domain/guia_investimentos.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';

void main() {
  group('PerfilInvestidor json', () {
    test('ida e volta', () {
      const perfil = PerfilInvestidor(
        objetivo: ObjetivoInvestimento.bem,
        prazo: PrazoInvestimento.medio,
        risco: ToleranciaRisco.conservador,
        observacao: 'Carro em 2028',
      );
      final lido = PerfilInvestidor.fromJson(perfil.toJson())!;
      expect(lido.objetivo, ObjetivoInvestimento.bem);
      expect(lido.prazo, PrazoInvestimento.medio);
      expect(lido.risco, ToleranciaRisco.conservador);
      expect(lido.observacao, 'Carro em 2028');
    });

    test('incompleto ou estranho vira null', () {
      expect(PerfilInvestidor.fromJson(null), isNull);
      expect(PerfilInvestidor.fromJson('x'), isNull);
      expect(
        PerfilInvestidor.fromJson({
          'objetivo': 'reserva',
          'prazo': 'curto',
          'risco': 'inexistente',
        }),
        isNull,
      );
    });
  });

  group('GuiaInvestimentos json', () {
    test('ida e volta com fontes e buscas', () {
      final guia = GuiaInvestimentos(
        texto: '## Título\nTexto',
        geradoEm: DateTime(2026, 10, 3, 14, 30),
        fontes: [
          FonteConsultada(
            titulo: 'Banco Central',
            url: Uri.parse('https://www.bcb.gov.br/publicacoes/focus'),
          ),
        ],
        buscas: const ['selic hoje'],
      );
      final lido = GuiaInvestimentos.fromJson(guia.toJson())!;
      expect(lido.texto, guia.texto);
      expect(lido.geradoEm, guia.geradoEm);
      expect(lido.fontes.single.titulo, 'Banco Central');
      expect(lido.fontes.single.url.host, 'www.bcb.gov.br');
      expect(lido.buscas, ['selic hoje']);
    });

    test('fonte que não é https é descartada; sem texto vira null', () {
      final lido = GuiaInvestimentos.fromJson({
        'texto': 'Guia',
        'gerado_em': '2026-10-03T17:30:00.000Z',
        'fontes': [
          {'titulo': 'ruim', 'url': 'javascript:alert(1)'},
          {'titulo': 'ok', 'url': 'https://sidra.ibge.gov.br/tabela/1737'},
        ],
      })!;
      expect(lido.fontes.map((f) => f.titulo), ['ok']);
      expect(lido.buscas, isEmpty);

      expect(GuiaInvestimentos.fromJson({'texto': ''}), isNull);
      expect(GuiaInvestimentos.fromJson({'texto': 'x'}), isNull);
    });
  });
}
