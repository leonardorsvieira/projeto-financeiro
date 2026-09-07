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

/// Fluxo do mês vigente (real + previsto).
final resumoMesProvider = Provider<ResumoMes>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final agora = DateTime.now();

  int entradas = 0;
  int saidas = 0;
  int previsto = 0;
  for (final l in todos) {
    final dataNoMes = l.data.year == agora.year && l.data.month == agora.month;
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
        venc != null && venc.year == agora.year && venc.month == agora.month;
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

/// Gastos do mês vigente agrupados por categoria, ordenados do maior para o
/// menor (lançamentos com `data` no mês).
final gastosPorCategoriaMesProvider = Provider<List<GastoCategoria>>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final agora = DateTime.now();

  final porCategoria = <String, int>{};
  for (final l in todos) {
    if (l.tipo == TipoLancamento.receita) continue;
    final dataNoMes = l.data.year == agora.year && l.data.month == agora.month;
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