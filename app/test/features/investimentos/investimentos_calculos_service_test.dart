import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/investimentos/application/investimentos_calculos_service.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';

void main() {
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
