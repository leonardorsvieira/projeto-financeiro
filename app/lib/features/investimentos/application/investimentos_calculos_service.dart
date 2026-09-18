import '../domain/investimento.dart';
import '../domain/movimento_investimento.dart';

/// Resultado do cálculo de Preço Médio e Rentabilidade por Ativo.
class PrecoMedioResultado {
  const PrecoMedioResultado({
    required this.precoMedioCents,
    required this.custoTotalCents,
    required this.quantidadeAtual,
    required this.patrimonioAtualCents,
    required this.lucroPrejuizoCents,
    required this.rentabilidadePercent,
  });

  final int precoMedioCents;
  final int custoTotalCents;
  final double quantidadeAtual;
  final int patrimonioAtualCents;
  final int lucroPrejuizoCents;
  final double rentabilidadePercent;

  double get precoMedioReais => precoMedioCents / 100.0;
  double get custoTotalReais => custoTotalCents / 100.0;
  double get patrimonioAtualReais => patrimonioAtualCents / 100.0;
  double get lucroPrejuizoReais => lucroPrejuizoCents / 100.0;

  bool get eLucro => lucroPrejuizoCents >= 0;
}

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

  /// Calcula o Preço Médio (PM) ponderado e Rentabilidade (% e R$) de um ativo.
  static PrecoMedioResultado calcularPrecoMedio({
    required Investimento investimento,
    required List<MovimentoInvestimento> movimentos,
  }) {
    // Ordena movimentos do mais antigo para o mais recente
    final movsOrdenados = List<MovimentoInvestimento>.from(movimentos)
      ..sort((a, b) => a.data.compareTo(b.data));

    double qtdAcumulada = 0.0;
    int custoAcumuladoCents = 0;
    int pmCents = 0;

    for (final m in movsOrdenados) {
      if (m.tipo == TipoMovimentoInvestimento.compra) {
        final valorCompra = (m.quantidade * m.precoUnitCents).round();
        custoAcumuladoCents += valorCompra;
        qtdAcumulada += m.quantidade;
        if (qtdAcumulada > 0) {
          pmCents = (custoAcumuladoCents / qtdAcumulada).round();
        }
      } else if (m.tipo == TipoMovimentoInvestimento.venda) {
        if (qtdAcumulada > 0) {
          final custoVenda = (m.quantidade * pmCents).round();
          custoAcumuladoCents -= custoVenda;
          qtdAcumulada -= m.quantidade;
          if (qtdAcumulada <= 0) {
            qtdAcumulada = 0;
            custoAcumuladoCents = 0;
            pmCents = 0;
          }
        }
      }
    }

    final qtdUsada = investimento.ePorQuantidade
        ? investimento.quantidade
        : (qtdAcumulada > 0 ? qtdAcumulada : 1.0);

    // Se houver PM calculado via histórico, utiliza ele; caso contrário, estima pelo preço atual ou saldo
    final pmFinalCents = pmCents > 0
        ? pmCents
        : (investimento.ePorQuantidade
            ? investimento.precoAtualCents
            : investimento.saldoCents);

    final custoTotalCents = investimento.ePorQuantidade
        ? (qtdUsada * pmFinalCents).round()
        : (custoAcumuladoCents > 0
            ? custoAcumuladoCents
            : investimento.saldoCents);

    final patrimonioAtualCents = investimento.patrimonioCents;
    final lucroPrejuizoCents = patrimonioAtualCents - custoTotalCents;

    double rentabilidade = 0.0;
    if (custoTotalCents > 0) {
      rentabilidade = (lucroPrejuizoCents / custoTotalCents) * 100.0;
    }

    return PrecoMedioResultado(
      precoMedioCents: pmFinalCents,
      custoTotalCents: custoTotalCents,
      quantidadeAtual: qtdUsada,
      patrimonioAtualCents: patrimonioAtualCents,
      lucroPrejuizoCents: lucroPrejuizoCents,
      rentabilidadePercent: rentabilidade,
    );
  }

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
