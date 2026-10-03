import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/dashboard/application/dados_analise_mes.dart';
import 'package:meubolso/features/dashboard/application/dashboard_providers.dart';

void main() {
  const resumo = ResumoMes(
    entradasCents: 500000,
    saidasCents: 350000,
    previstoCents: 12000,
    resgatesCents: 10000,
    aplicacoesCents: 30000,
  );
  const gastos = [
    GastoCategoria(categoria: 'Moradia', valorCents: 200000),
    GastoCategoria(categoria: 'Alimentação', valorCents: 150000),
  ];

  group('dadosAnaliseDoMes', () {
    test('valores em reais (nunca centavos crus) e categorias legíveis', () {
      final texto = dadosAnaliseDoMes(
        resumo: resumo,
        gastos: gastos,
        mes: DateTime(2026, 9),
        hoje: DateTime(2026, 10, 3),
      );

      expect(texto, contains('setembro de 2026 (mês encerrado)'));
      expect(texto, contains('Receitas do mês: R\$ 5.000,00'));
      expect(texto, contains('Despesas do mês: R\$ 3.500,00'));
      // 5.000 − 3.500 + 100 − 300
      expect(texto, contains('Saldo do mês: R\$ 1.300,00'));
      expect(texto, contains('Resgatado de investimentos'));
      expect(texto, contains('Aplicado em investimentos'));
      expect(texto, contains('ainda não foram pagas: R\$ 120,00'));
      expect(texto, contains('- Moradia: R\$ 2.000,00 (57% das despesas)'));
      expect(texto, contains('- Alimentação: R\$ 1.500,00 (43%'));
      expect(texto, isNot(contains('350000')));
      expect(texto, isNot(contains('Instance of')));
    });

    test('mês corrente avisa que os números são parciais', () {
      final texto = dadosAnaliseDoMes(
        resumo: resumo,
        gastos: gastos,
        mes: DateTime(2026, 10),
        hoje: DateTime(2026, 10, 3),
      );
      expect(texto, contains('mês em andamento: dia 3 de 31'));
    });

    test('sem investimento nem previsto, essas linhas não aparecem', () {
      final texto = dadosAnaliseDoMes(
        resumo: const ResumoMes(
          entradasCents: 0,
          saidasCents: 1000,
          previstoCents: 0,
        ),
        gastos: const [GastoCategoria(categoria: 'Lazer', valorCents: 1000)],
        mes: DateTime(2026, 8),
        hoje: DateTime(2026, 10, 3),
      );
      expect(texto, isNot(contains('investimentos')));
      expect(texto, isNot(contains('não foram pagas')));
    });
  });

  test('mesSemLancamentos', () {
    expect(
      mesSemLancamentos(
        const ResumoMes(entradasCents: 0, saidasCents: 0, previstoCents: 0),
        const [],
      ),
      isTrue,
    );
    expect(mesSemLancamentos(resumo, gastos), isFalse);
  });
}
