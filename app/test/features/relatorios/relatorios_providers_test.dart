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
          // Sem banco conectado: sem patrimônio real, vale o saldo do período.
          patrimonioRealAtualProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      container.listen(relatoriosComparativosProvider, (_, _) {});
      await container.read(lancamentosStreamProvider.future);

      final dados = container.read(relatoriosComparativosProvider);

      expect(dados.pontos.length, 6);
      expect(dados.totalEntradasCents, 1000000);
      expect(dados.totalSaidasCents, 300000);
      expect(dados.saldoTotalCents, 700000);
      expect(dados.mediaEntradasReais, 10000.0 / 6);
      expect(dados.mediaSaidasReais, 3000.0 / 6);
      // Sem banco conectado não há patrimônio real (vale o saldo do período).
      expect(dados.patrimonioReal, isFalse);
    });

    test('resgate soma e aplicação subtrai só no saldo (não no patrimônio)',
        () async {
      final agora = DateTime.now();
      final mesAtual = DateTime(agora.year, agora.month, 1);
      Lancamento l(String id, int cents, String categoria, TipoLancamento t) =>
          Lancamento(
            id: id,
            data: mesAtual,
            tipo: t,
            descricao: id,
            categoria: categoria,
            formaPagamento: 'Pix',
            valorCents: cents,
            createdAt: agora,
            updatedAt: agora,
          );

      final lancamentos = [
        l('salario', 500000, 'Trabalho', TipoLancamento.receita),
        l('aluguel', 200000, 'Moradia', TipoLancamento.despesa),
        l('resgate', 150000, categoriaMovimentacaoInvestimento,
            TipoLancamento.receita),
        l('aplicacao', 50000, categoriaMovimentacaoInvestimento,
            TipoLancamento.despesa),
        l('transf', 99999, categoriaTransferenciaEntreContas,
            TipoLancamento.receita),
        // Estorno no cartão: abate as despesas, não é receita.
        l('estorno', 30000, 'Compras', TipoLancamento.receita)
            .copyWith(formaPagamento: 'Cartão: Mercado Pago'),
      ];

      final container = ProviderContainer(
        overrides: [
          lancamentosStreamProvider
              .overrideWith((ref) => Stream.value(lancamentos)),
          investimentosStreamProvider.overrideWith((ref) => Stream.value([])),
          patrimonioRealAtualProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      container.listen(relatoriosComparativosProvider, (_, _) {});
      await container.read(lancamentosStreamProvider.future);

      final dados = container.read(relatoriosComparativosProvider);
      final atual = dados.pontos.last;

      expect(dados.totalEntradasCents, 500000);
      expect(dados.totalSaidasCents, 170000); // 2000 − 300 de estorno
      expect(dados.totalInvestimentosCents, 100000);
      expect(dados.saldoTotalCents, 430000);
      expect(atual.investimentosCents, 100000);
      expect(atual.saldoMesCents, 430000);
      expect(dados.temMovimentoInvestimento, isTrue);
      // Saldo acumulado/patrimônio não conta aplicação nem resgate.
      expect(atual.patrimonioAcumuladoCents, 330000);
    });
  });

  group('evolucaoPatrimonialPorMes', () {
    final agora = DateTime(2026, 10, 2, 15);
    final meses = [DateTime(2026, 8), DateTime(2026, 9), DateTime(2026, 10)];
    Lancamento l(DateTime data, int cents, {bool receita = false}) =>
        Lancamento(
          id: '$data$cents',
          descricao: 'x',
          valorCents: cents,
          categoria: 'Outros',
          formaPagamento: 'Pix',
          data: data,
          tipo: receita ? TipoLancamento.receita : TipoLancamento.despesa,
          createdAt: agora,
          updatedAt: agora,
        );

    test('com patrimônio real: parte de hoje e desconta o que veio depois', () {
      final valores = evolucaoPatrimonialPorMes(
        meses: meses,
        lancamentos: [
          l(DateTime(2026, 8, 10), 300000, receita: true),
          l(DateTime(2026, 9, 5), 100000),
          l(DateTime(2026, 10, 1), 50000),
          // Vencimento futuro: ainda não aconteceu, não mexe em nada.
          l(DateTime(2026, 10, 20), 999999),
        ],
        agora: agora,
        patrimonioAtualCents: 1000000,
      );
      // Out = hoje; Set = hoje + 500 gastos em out; Ago = + 1000 gastos em set.
      expect(valores, [1150000, 1050000, 1000000]);
    });

    test('nunca soma de novo o que já está nos investimentos', () {
      // Recebeu 37 mil ao longo do ano e aplicou tudo (aplicação é neutra e
      // não entra aqui): o patrimônio é o de hoje, não 37 mil + investimentos.
      final valores = evolucaoPatrimonialPorMes(
        meses: meses,
        lancamentos: [l(DateTime(2026, 8, 1), 3700000, receita: true)],
        agora: agora,
        patrimonioAtualCents: 3400000,
      );
      expect(valores.last, 3400000);
    });

    test('sem patrimônio real: saldo acumulado desde o início do período', () {
      final valores = evolucaoPatrimonialPorMes(
        meses: meses,
        lancamentos: [
          l(DateTime(2026, 7, 31), 999999, receita: true), // antes do período
          l(DateTime(2026, 8, 10), 300000, receita: true),
          l(DateTime(2026, 9, 5), 100000),
        ],
        agora: agora,
      );
      expect(valores, [300000, 200000, 200000]);
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
            saldoMesCents: 330000,
            patrimonioAcumuladoCents: 350000,
            investimentosCents: -20000,
          ),
        ],
        totalEntradasCents: 500000,
        totalSaidasCents: 150000,
        saldoTotalCents: 330000,
        totalInvestimentosCents: -20000,
        patrimonioInicialCents: 350000,
        patrimonioAtualCents: 350000,
        variacaoPatrimonialPercent: 0.0,
      );

      final csv = ExportarService.gerarCSVComparativo(dados);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Mês/Ano;Entradas (R\$);Saídas (R\$);Investimentos (R\$);Saldo do Mês (R\$);Patrimônio Acumulado (R\$)'));
      expect(csv, contains('Setembro 2026;5000,00;1500,00;-200,00;3300,00;3500,00'));
    });
  });
}
