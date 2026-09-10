import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart' show TipoLancamento;

/// Resumo do fluxo do mês vigente (entradas e saídas + previsto).
///
/// [entradasCents] soma receitas com data no mês; [saidasCents] soma despesas
/// com data no mês (alias de compat: [realCents]); [previstoCents] soma
/// despesas que vencem no mês mas ainda não foram contabilizadas (vencimento
/// no mês e data fora dele). Receitas não têm previsto.
class ResumoMes {
  const ResumoMes({
    required this.entradasCents,
    required this.saidasCents,
    required this.previstoCents,
  });

  final int entradasCents;
  final int saidasCents;
  final int previstoCents;

  /// Alias de compatibilidade: saídas do mês.
  int get realCents => saidasCents;

  /// Saldo do mês: entradas − saídas.
  int get saldoCents => entradasCents - saidasCents;

  /// Total de gasto (saídas + previsto) — mantém semântica de gasto.
  int get totalCents => saidasCents + previstoCents;

  @override
  String toString() =>
      'ResumoMes(entradas: $entradasCents, saídas: $saidasCents, '
      'previsto: $previstoCents)';
}

/// Mês e Ano selecionado para o Dashboard e Histórico.
final mesSelecionadoProvider = NotifierProvider<MesSelecionadoNotifier, DateTime>(
  MesSelecionadoNotifier.new,
);

class MesSelecionadoNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month);
  }

  void selecionarMes(DateTime mesAno) {
    state = DateTime(mesAno.year, mesAno.month);
  }

  void mesAnterior() {
    state = DateTime(state.year, state.month - 1);
  }

  void proximoMes() {
    state = DateTime(state.year, state.month + 1);
  }

  void resetarParaAtual() {
    final agora = DateTime.now();
    state = DateTime(agora.year, agora.month);
  }
}

/// Fluxo do mês selecionado (real + previsto).
final resumoMesProvider = Provider<ResumoMes>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final mesAno = ref.watch(mesSelecionadoProvider);

  int entradas = 0;
  int saidas = 0;
  int previsto = 0;
  for (final l in todos) {
    final dataNoMes = l.data.year == mesAno.year && l.data.month == mesAno.month;
    final receita = l.tipo == TipoLancamento.receita;
    if (dataNoMes) {
      if (receita) {
        entradas += l.valorCents;
      } else {
        saidas += l.valorCents;
      }
    }

    if (receita) continue;
    final venc = l.vencimento;
    final venceNoMes =
        venc != null && venc.year == mesAno.year && venc.month == mesAno.month;
    if (venceNoMes && !dataNoMes) previsto += l.valorCents;
  }
  return ResumoMes(
    entradasCents: entradas,
    saidasCents: saidas,
    previstoCents: previsto,
  );
});

/// Gasto agregado por categoria no mês vigente.
class GastoCategoria {
  const GastoCategoria({
    required this.categoria,
    required this.valorCents,
  });

  final String categoria;
  final int valorCents;
}

/// Gastos do mês selecionado agrupados por categoria, ordenados do maior para o
/// menor (lançamentos com `data` no mês).
final gastosPorCategoriaMesProvider = Provider<List<GastoCategoria>>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final mesAno = ref.watch(mesSelecionadoProvider);

  final porCategoria = <String, int>{};
  for (final l in todos) {
    if (l.tipo == TipoLancamento.receita) continue;
    final dataNoMes = l.data.year == mesAno.year && l.data.month == mesAno.month;
    if (dataNoMes) {
      porCategoria.update(l.categoria, (v) => v + l.valorCents,
          ifAbsent: () => l.valorCents);
    }
  }

  final list = porCategoria.entries
      .map((e) => GastoCategoria(categoria: e.key, valorCents: e.value))
      .toList()
    ..sort((a, b) => b.valorCents.compareTo(a.valorCents));
  return list;
});

class MesHistorico {
  const MesHistorico({
    required this.mesAno,
    required this.resumo,
  });

  final DateTime mesAno;
  final ResumoMes resumo;
}

/// Histórico dos últimos 6 meses com totais de fluxo para comparativo.
final historicoUltimosMesesProvider = Provider<List<MesHistorico>>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final agora = DateTime.now();

  final resultado = <MesHistorico>[];
  for (var i = 0; i < 6; i++) {
    final mes = DateTime(agora.year, agora.month - i);
    int entradas = 0;
    int saidas = 0;
    int previsto = 0;
    for (final l in todos) {
      final dataNoMes = l.data.year == mes.year && l.data.month == mes.month;
      final receita = l.tipo == TipoLancamento.receita;
      if (dataNoMes) {
        if (receita) {
          entradas += l.valorCents;
        } else {
          saidas += l.valorCents;
        }
      }
      if (receita) continue;
      final venc = l.vencimento;
      final venceNoMes =
          venc != null && venc.year == mes.year && venc.month == mes.month;
      if (venceNoMes && !dataNoMes) previsto += l.valorCents;
    }
    resultado.add(
      MesHistorico(
        mesAno: mes,
        resumo: ResumoMes(
          entradasCents: entradas,
          saidasCents: saidas,
          previstoCents: previsto,
        ),
      ),
    );
  }
  return resultado;
});