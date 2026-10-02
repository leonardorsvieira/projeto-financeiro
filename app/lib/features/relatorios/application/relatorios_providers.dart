import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart';
import '../../open_finance/application/open_finance_providers.dart';

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
    this.patrimonioReal = false,
  });

  final List<PontoHistoricoMes> pontos;
  final int totalEntradasCents;
  final int totalSaidasCents;
  final int saldoTotalCents;
  final int patrimonioInicialCents;
  final int patrimonioAtualCents;
  final double variacaoPatrimonialPercent;

  /// true: valores partem do patrimônio real (saldo das contas + investimentos
  /// − faturas, do Open Finance). false: só o saldo acumulado no período.
  final bool patrimonioReal;

  double get mediaEntradasReais =>
      pontos.isEmpty ? 0 : (totalEntradasCents / 100.0) / pontos.length;
  double get mediaSaidasReais =>
      pontos.isEmpty ? 0 : (totalSaidasCents / 100.0) / pontos.length;
}

/// Patrimônio real de hoje: saldo das contas + investimentos − faturas em
/// aberto, do Open Finance. Null se nenhuma conta conectada informou saldo
/// (sem isso não há como saber quanto a pessoa tem).
final patrimonioRealAtualProvider = Provider<int?>((ref) {
  final contas = ref.watch(contasConectadasProvider).value ?? const [];
  final comSaldo = contas.where(
    (c) => c.saldoContasCents != null || c.faturaCartoesCents != null,
  );
  if (comSaldo.isEmpty) return null;
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  final totalInvestimentos =
      investimentos.fold<int>(0, (acc, inv) => acc + inv.patrimonioCents);
  return comSaldo.fold<int>(
        0,
        (acc, c) =>
            acc + (c.saldoContasCents ?? 0) - (c.faturaCartoesCents ?? 0),
      ) +
      totalInvestimentos;
});

int _fluxo(Lancamento l) =>
    l.tipo == TipoLancamento.receita ? l.valorCents : -l.valorCents;

/// Valor de cada mês de [meses] (do mais antigo ao atual) na evolução.
///
/// Com [patrimonioAtualCents] (patrimônio real de hoje), reconstrói para
/// trás: o fim de cada mês é o patrimônio de hoje menos o que entrou e saiu
/// depois dele (até [agora]). Sem ele, é o saldo acumulado desde o início do
/// período. [lancamentos] deve vir sem as movimentações neutras (transferência
/// entre contas próprias e aplicação/resgate não mudam o patrimônio).
List<int> evolucaoPatrimonialPorMes({
  required List<DateTime> meses,
  required List<Lancamento> lancamentos,
  required DateTime agora,
  int? patrimonioAtualCents,
}) {
  if (meses.isEmpty) return const [];
  final valores = <int>[];
  for (final mes in meses) {
    final fimDoMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);
    final corte = fimDoMes.isAfter(agora) ? agora : fimDoMes;
    if (patrimonioAtualCents != null) {
      final depois = lancamentos
          .where((l) => l.data.isAfter(corte) && !l.data.isAfter(agora))
          .fold<int>(0, (s, l) => s + _fluxo(l));
      valores.add(patrimonioAtualCents - depois);
    } else {
      final inicio = DateTime(meses.first.year, meses.first.month);
      final noPeriodo = lancamentos
          .where((l) => !l.data.isBefore(inicio) && !l.data.isAfter(corte))
          .fold<int>(0, (s, l) => s + _fluxo(l));
      valores.add(noPeriodo);
    }
  }
  return valores;
}

/// Provider que calcula o relatório comparativo com base no número de meses selecionado.
final relatoriosComparativosProvider =
    Provider<DadosRelatorioComparativo>((ref) {
  final numMeses = ref.watch(numMesesRelatorioProvider);
  final lancamentos = ref.watch(lancamentosContabeisProvider);
  final patrimonioAtualReal = ref.watch(patrimonioRealAtualProvider);

  final agora = DateTime.now();

  // Gera lista de meses do mais antigo ao mais recente
  final meses = List.generate(numMeses, (i) {
    final delta = (numMeses - 1) - i;
    return DateTime(agora.year, agora.month - delta);
  });

  final evolucao = evolucaoPatrimonialPorMes(
    meses: meses,
    lancamentos: lancamentos,
    agora: agora,
    patrimonioAtualCents: patrimonioAtualReal,
  );

  int totalEntradas = 0;
  int totalSaidas = 0;
  final pontos = <PontoHistoricoMes>[];

  for (var i = 0; i < meses.length; i++) {
    final mes = meses[i];
    int entradasNoMes = 0;
    int saidasNoMes = 0;

    for (final l in lancamentos) {
      if (l.data.year == mes.year && l.data.month == mes.month) {
        if (l.tipo == TipoLancamento.receita) {
          entradasNoMes += l.valorCents;
        } else {
          saidasNoMes += l.valorCents;
        }
      }
    }

    totalEntradas += entradasNoMes;
    totalSaidas += saidasNoMes;
    final patrimonioAcumulado = evolucao[i];

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
    patrimonioReal: patrimonioAtualReal != null,
  );
});
