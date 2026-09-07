import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/application/lancamentos_providers.dart';

/// Resumo dos gastos do mês vigente.
///
/// Na Fase 6 ainda não existe conceito de receita, então o "saldo" é apenas a
/// soma de saídas. [realCents] soma lançamentos com data no mês vigente;
/// [previstoCents] soma lançamentos que vencem no mês mas ainda não foram
/// contabilizados como gasto do mês (vencimento no mês e data fora dele).
class ResumoMes {
  const ResumoMes({required this.realCents, required this.previstoCents});

  final int realCents;
  final int previstoCents;

  int get totalCents => realCents + previstoCents;

  @override
  String toString() =>
      'ResumoMes(real: $realCents, previsto: $previstoCents)';
}

/// Soma de gastos do mês vigente (real + previsto).
final resumoMesProvider = Provider<ResumoMes>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final agora = DateTime.now();

  int real = 0;
  int previsto = 0;
  for (final l in todos) {
    final dataNoMes = l.data.year == agora.year && l.data.month == agora.month;
    if (dataNoMes) real += l.valorCents;

    final venc = l.vencimento;
    final venceNoMes =
        venc != null && venc.year == agora.year && venc.month == agora.month;
    if (venceNoMes && !dataNoMes) previsto += l.valorCents;
  }
  return ResumoMes(realCents: real, previstoCents: previsto);
});