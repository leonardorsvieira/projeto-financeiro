import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart';

/// Notifier para o número de meses do relatório (ex: 6 ou 12 meses).
final numMesesRelatorioProvider =
    NotifierProvider<NumMesesRelatorioNotifier, int>(
  NumMesesRelatorioNotifier.new,
);

class NumMesesRelatorioNotifier extends Notifier<int> {
  @override
  int build() => 6;

  void setMeses(int meses) {
    if (meses == 6 || meses == 12) {
      state = meses;
    }
  }
}

/// Dados consolidados de um mês no histórico.
class PontoHistoricoMes {
  const PontoHistoricoMes({
    required this.mesAno,
    required this.entradasCents,
    required this.saidasCents,
    required this.saldoMesCents,
    required this.patrimonioAcumuladoCents,
  });

  final DateTime mesAno;
  final int entradasCents;
  final int saidasCents;
  final int saldoMesCents;
  final int patrimonioAcumuladoCents;

  double get entradasReais => entradasCents / 100.0;
  double get saidasReais => saidasCents / 100.0;
  double get saldoMesReais => saldoMesCents / 100.0;
  double get patrimonioAcumuladoReais => patrimonioAcumuladoCents / 100.0;
}

/// Dados completos agregados para o relatório comparativo.
class DadosRelatorioComparativo {
  const DadosRelatorioComparativo({
    required this.pontos,
    required this.totalEntradasCents,
    required this.totalSaidasCents,
    required this.saldoTotalCents,
    required this.patrimonioInicialCents,
    required this.patrimonioAtualCents,
    required this.variacaoPatrimonialPercent,
  });

  final List<PontoHistoricoMes> pontos;
  final int totalEntradasCents;
  final int totalSaidasCents;
  final int saldoTotalCents;
  final int patrimonioInicialCents;
  final int patrimonioAtualCents;
  final double variacaoPatrimonialPercent;

  double get mediaEntradasReais =>
      pontos.isEmpty ? 0 : (totalEntradasCents / 100.0) / pontos.length;
  double get mediaSaidasReais =>
      pontos.isEmpty ? 0 : (totalSaidasCents / 100.0) / pontos.length;
}

/// Provider que calcula o relatório comparativo com base no número de meses selecionado.
final relatoriosComparativosProvider =
    Provider<DadosRelatorioComparativo>((ref) {
  final numMeses = ref.watch(numMesesRelatorioProvider);
  final lancamentos = ref.watch(lancamentosStreamProvider).value ?? [];
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];

  final agora = DateTime.now();

  // Gera lista de meses do mais antigo ao mais recente
  final meses = List.generate(numMeses, (i) {
    final delta = (numMeses - 1) - i;
    return DateTime(agora.year, agora.month - delta);
  });

  // Calcula valor total dos investimentos atuais
  final totalInvestimentosCents = investimentos.fold<int>(
    0,
    (acc, inv) => acc + inv.patrimonioCents,
  );

  int totalEntradas = 0;
  int totalSaidas = 0;
  final pontos = <PontoHistoricoMes>[];

  for (final mes in meses) {
    final fimDoMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);

    int entradasNoMes = 0;
    int saidasNoMes = 0;

    // Calcula acumulado até o fim deste mês
    int acumuladoEntradasAteMes = 0;
    int acumuladoSaidasAteMes = 0;

    for (final l in lancamentos) {
      final receita = l.tipo == TipoLancamento.receita;

      // Se ocorreu neste mês exato
      if (l.data.year == mes.year && l.data.month == mes.month) {
        if (receita) {
          entradasNoMes += l.valorCents;
        } else {
          saidasNoMes += l.valorCents;
        }
      }

      // Se ocorreu até o fim deste mês
      if (l.data.isBefore(fimDoMes) || l.data.isAtSameMomentAs(fimDoMes)) {
        if (receita) {
          acumuladoEntradasAteMes += l.valorCents;
        } else {
          acumuladoSaidasAteMes += l.valorCents;
        }
      }
    }

    totalEntradas += entradasNoMes;
    totalSaidas += saidasNoMes;

    final saldoAcumuladoSemInvest =
        acumuladoEntradasAteMes - acumuladoSaidasAteMes;
    final patrimonioAcumulado =
        saldoAcumuladoSemInvest + totalInvestimentosCents;

    pontos.add(
      PontoHistoricoMes(
        mesAno: mes,
        entradasCents: entradasNoMes,
        saidasCents: saidasNoMes,
        saldoMesCents: entradasNoMes - saidasNoMes,
        patrimonioAcumuladoCents: patrimonioAcumulado,
      ),
    );
  }

  final patrimonioInicial =
      pontos.isNotEmpty ? pontos.first.patrimonioAcumuladoCents : 0;
  final patrimonioAtual =
      pontos.isNotEmpty ? pontos.last.patrimonioAcumuladoCents : 0;

  double variacaoPercent = 0.0;
  if (patrimonioInicial != 0) {
    variacaoPercent =
        ((patrimonioAtual - patrimonioInicial) / patrimonioInicial.abs()) *
            100.0;
  } else if (patrimonioAtual > 0) {
    variacaoPercent = 100.0;
  }

  return DadosRelatorioComparativo(
    pontos: pontos,
    totalEntradasCents: totalEntradas,
    totalSaidasCents: totalSaidas,
    saldoTotalCents: totalEntradas - totalSaidas,
    patrimonioInicialCents: patrimonioInicial,
    patrimonioAtualCents: patrimonioAtual,
    variacaoPatrimonialPercent: variacaoPercent,
  );
});
