import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/investimentos/application/investimentos_calculos_service.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/movimento_investimento.dart';

void main() {
  group('InvestimentosCalculosService - Preço Médio e Rentabilidade', () {
    test('calcula PM ponderado para compras consecutivas', () {
      final inv = const Investimento(
        id: '1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 200,
        precoAtualCents: 3500, // R$ 35,00
      );

      final movs = [
        MovimentoInvestimento(
          id: 'm1',
          investimentoId: '1',
          tipo: TipoMovimentoInvestimento.compra,
          quantidade: 100,
          precoUnitCents: 2000, // R$ 20,00 -> R$ 2.000,00
          data: DateTime(2026, 1, 10),
        ),
        MovimentoInvestimento(
          id: 'm2',
          investimentoId: '1',
          tipo: TipoMovimentoInvestimento.compra,
          quantidade: 100,
          precoUnitCents: 3000, // R$ 30,00 -> R$ 3.000,00
          data: DateTime(2026, 2, 10),
        ),
      ];

      final res = InvestimentosCalculosService.calcularPrecoMedio(
        investimento: inv,
        movimentos: movs,
      );

      // Custo Total = R$ 5.000,00 (500000 cents)
      // PM = R$ 25,00 (2500 cents)
      // Patrimônio Atual = 200 * R$ 35,00 = R$ 7.000,00 (700000 cents)
      // Lucro = R$ 2.000,00 (200000 cents) -> 40%
      expect(res.precoMedioCents, 2500);
      expect(res.custoTotalCents, 500000);
      expect(res.patrimonioAtualCents, 700000);
      expect(res.lucroPrejuizoCents, 200000);
      expect(res.rentabilidadePercent, 40.0);
    });

    test('mantém PM inalterado após venda parcial', () {
      final inv = const Investimento(
        id: '1',
        classe: TipoClasseInvestimento.fii,
        nome: 'HGLG11',
        quantidade: 50,
        precoAtualCents: 16000, // R$ 160,00
      );

      final movs = [
        MovimentoInvestimento(
          id: 'm1',
          investimentoId: '1',
          tipo: TipoMovimentoInvestimento.compra,
          quantidade: 100,
          precoUnitCents: 15000, // R$ 150,00 -> R$ 15.000,00
          data: DateTime(2026, 1, 10),
        ),
        MovimentoInvestimento(
          id: 'm2',
          investimentoId: '1',
          tipo: TipoMovimentoInvestimento.venda,
          quantidade: 50,
          precoUnitCents: 17000, // Vendeu 50 cotas
          data: DateTime(2026, 3, 10),
        ),
      ];

      final res = InvestimentosCalculosService.calcularPrecoMedio(
        investimento: inv,
        movimentos: movs,
      );

      // PM deve continuar R$ 150,00 (15000 cents)
      // Qtd restante = 50 cotas -> Custo total = R$ 7.500,00 (750000 cents)
      expect(res.precoMedioCents, 15000);
      expect(res.custoTotalCents, 750000);
    });
  });

  group('InvestimentosCalculosService - Calculadora de Rebalanceamento', () {
    test('sugere aporte prioritariamente na classe mais descontada', () {
      final investimentos = [
        const Investimento(
          id: '1',
          classe: TipoClasseInvestimento.rendaFixa,
          nome: 'CDB',
          saldoCents: 800000, // R$ 8.000,00 (80% da carteira)
        ),
        const Investimento(
          id: '2',
          classe: TipoClasseInvestimento.acao,
          nome: 'VALE3',
          quantidade: 100,
          precoAtualCents: 2000, // R$ 2.000,00 (20% da carteira)
        ),
      ];

      final metas = {
        TipoClasseInvestimento.rendaFixa: 50.0,
        TipoClasseInvestimento.acao: 50.0,
      };

      // Novo Aporte de R$ 2.000,00 (200000 cents)
      // Novo total = R$ 12.000,00 -> Meta Ações (50%) = R$ 6.000,00
      // Déficit Ações = R$ 6.000 - R$ 2.000 = R$ 4.000
      // Todo o aporte de R$ 2.000 deve ir para Ações
      final sugestoes = InvestimentosCalculosService.calcularRebalanceamento(
        investimentos: investimentos,
        metasPercentuais: metas,
        aporteCents: 200000,
      );

      final sugAcoes =
          sugestoes.firstWhere((s) => s.classe == TipoClasseInvestimento.acao);
      final sugRF = sugestoes
          .firstWhere((s) => s.classe == TipoClasseInvestimento.rendaFixa);

      expect(sugAcoes.valorSugeridoCents, 200000);
      expect(sugRF.valorSugeridoCents, 0);
    });
  });
}
