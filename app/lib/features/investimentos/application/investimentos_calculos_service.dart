import '../domain/investimento.dart';

/// Sugestão de aporte para rebalanceamento de classe.
class SugestaoAporteClasse {
  const SugestaoAporteClasse({
    required this.classe,
    required this.patrimonioAtualCents,
    required this.percentualAtual,
    required this.percentualAlvo,
    required this.valorSugeridoCents,
  });

  final TipoClasseInvestimento classe;
  final int patrimonioAtualCents;
  final double percentualAtual;
  final double percentualAlvo;
  final int valorSugeridoCents;

  double get patrimonioAtualReais => patrimonioAtualCents / 100.0;
  double get valorSugeridoReais => valorSugeridoCents / 100.0;
}

class InvestimentosCalculosService {
  InvestimentosCalculosService._();

  /// Calcula as sugestões de rebalanceamento da carteira com base no aporte e metas por classe.
  static List<SugestaoAporteClasse> calcularRebalanceamento({
    required List<Investimento> investimentos,
    required Map<TipoClasseInvestimento, double> metasPercentuais,
    required int aporteCents,
  }) {
    // 1. Calcula patrimônio atual por classe
    final patrimonioPorClasse = <TipoClasseInvestimento, int>{};
    int patrimonioTotalAtualCents = 0;

    for (final classe in TipoClasseInvestimento.values) {
      patrimonioPorClasse[classe] = 0;
    }

    for (final inv in investimentos) {
      patrimonioPorClasse[inv.classe] =
          (patrimonioPorClasse[inv.classe] ?? 0) + inv.patrimonioCents;
      patrimonioTotalAtualCents += inv.patrimonioCents;
    }

    final novoPatrimonioTotalCents = patrimonioTotalAtualCents + aporteCents;

    // 2. Determina o déficit financeiro de cada classe para atingir a % ideal
    final deficitPorClasse = <TipoClasseInvestimento, int>{};
    int totalDeficitCents = 0;

    for (final classe in TipoClasseInvestimento.values) {
      final metaPct = metasPercentuais[classe] ?? 0.0;
      final patrimonioIdealCents =
          (novoPatrimonioTotalCents * (metaPct / 100.0)).round();
      final patrimonioAtual = patrimonioPorClasse[classe] ?? 0;
      final deficit = patrimonioIdealCents - patrimonioAtual;

      if (deficit > 0) {
        deficitPorClasse[classe] = deficit;
        totalDeficitCents += deficit;
      } else {
        deficitPorClasse[classe] = 0;
      }
    }

    // 3. Distribui o valor do aporte proporcionalmente ao déficit de cada classe
    final sugestoes = <SugestaoAporteClasse>[];

    for (final classe in TipoClasseInvestimento.values) {
      final patrimonioAtual = patrimonioPorClasse[classe] ?? 0;
      final pctAtual = patrimonioTotalAtualCents > 0
          ? (patrimonioAtual / patrimonioTotalAtualCents) * 100.0
          : 0.0;
      final pctAlvo = metasPercentuais[classe] ?? 0.0;
      final deficit = deficitPorClasse[classe] ?? 0;

      int valorSugerido = 0;
      if (aporteCents > 0 && totalDeficitCents > 0 && deficit > 0) {
        if (aporteCents >= totalDeficitCents) {
          valorSugerido = deficit;
        } else {
          valorSugerido = ((deficit / totalDeficitCents) * aporteCents).round();
        }
      }

      sugestoes.add(
        SugestaoAporteClasse(
          classe: classe,
          patrimonioAtualCents: patrimonioAtual,
          percentualAtual: pctAtual,
          percentualAlvo: pctAlvo,
          valorSugeridoCents: valorSugerido,
        ),
      );
    }

    return sugestoes;
  }
}
