import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/lancamentos/application/exportar_service.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/relatorios/application/relatorios_providers.dart';

void main() {
  group('numMesesRelatorioProvider', () {
    test('inicia com 6 meses e permite alternar para 12', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(numMesesRelatorioProvider), 6);

      container.read(numMesesRelatorioProvider.notifier).setMeses(12);
      expect(container.read(numMesesRelatorioProvider), 12);

      // Valores inválidos não devem alterar o estado
      container.read(numMesesRelatorioProvider.notifier).setMeses(8);
      expect(container.read(numMesesRelatorioProvider), 12);
    });
  });

  group('relatoriosComparativosProvider', () {
    test('calcula corretamente totais, média e pontos dos últimos 6 meses', () async {
      final agora = DateTime.now();
      final mesAtual = DateTime(agora.year, agora.month, 10);
      final mesPassado = DateTime(agora.year, agora.month - 1, 15);

      final List<Lancamento> lancamentos = [
        Lancamento(
          id: '1',
          data: mesPassado,
          tipo: TipoLancamento.receita,
          descricao: 'Salário Passado',
          categoria: 'Trabalho',
          formaPagamento: 'Pix',
          valorCents: 500000,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '2',
          data: mesPassado,
          tipo: TipoLancamento.despesa,
          descricao: 'Aluguel Passado',
          categoria: 'Moradia',
          formaPagamento: 'Pix',
          valorCents: 200000,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '3',
          data: mesAtual,
          tipo: TipoLancamento.receita,
          descricao: 'Salário Atual',
          categoria: 'Trabalho',
          formaPagamento: 'Pix',
          valorCents: 500000,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '4',
          data: mesAtual,
          tipo: TipoLancamento.despesa,
          descricao: 'Mercado',
          categoria: 'Alimentação',
          formaPagamento: 'Cartão',
          valorCents: 100000,
          createdAt: agora,
          updatedAt: agora,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          lancamentosStreamProvider
              .overrideWith((ref) => Stream.value(lancamentos)),
          investimentosStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      container.listen(relatoriosComparativosProvider, (_, _) {});
      await container.read(lancamentosStreamProvider.future);
      await container.read(investimentosStreamProvider.future);

      final dados = container.read(relatoriosComparativosProvider);

      expect(dados.pontos.length, 6);
      expect(dados.totalEntradasCents, 1000000);
      expect(dados.totalSaidasCents, 300000);
      expect(dados.saldoTotalCents, 700000);
      expect(dados.mediaEntradasReais, 10000.0 / 6);
      expect(dados.mediaSaidasReais, 3000.0 / 6);
    });
  });

  group('ExportarService - CSV Comparativo', () {
    test('gera CSV com BOM UTF-8 e colunas formatadas', () {
      final dados = DadosRelatorioComparativo(
        pontos: [
          PontoHistoricoMes(
            mesAno: DateTime(2026, 9),
            entradasCents: 500000,
            saidasCents: 150000,
            saldoMesCents: 350000,
            patrimonioAcumuladoCents: 350000,
          ),
        ],
        totalEntradasCents: 500000,
        totalSaidasCents: 150000,
        saldoTotalCents: 350000,
        patrimonioInicialCents: 350000,
        patrimonioAtualCents: 350000,
        variacaoPatrimonialPercent: 0.0,
      );

      final csv = ExportarService.gerarCSVComparativo(dados);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Mês/Ano;Entradas (R\$);Saídas (R\$);Saldo do Mês (R\$);Patrimônio Acumulado (R\$)'));
      expect(csv, contains('Setembro 2026;5000,00;1500,00;3500,00;3500,00'));
    });
  });
}
