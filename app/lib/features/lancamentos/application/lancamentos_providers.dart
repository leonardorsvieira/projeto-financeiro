import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_lancamentos_repository.dart';
import '../domain/lancamento.dart';
import '../domain/lancamentos_repository.dart';

final lancamentosRepositoryProvider = Provider<LancamentosRepository>(
  (ref) => SupabaseLancamentosRepository(),
);

final lancamentosStreamProvider = StreamProvider<List<Lancamento>>((ref) {
  return ref.watch(lancamentosRepositoryProvider).watch();
});

final lancamentoByIdProvider =
    FutureProvider.family<Lancamento?, String>((ref, id) {
  return ref.watch(lancamentosRepositoryProvider).findById(id);
});

/// Lista de lançamentos com vencimento futuro (>= hoje), ordenados por vencimento ascendente.
final proximosVencimentosProvider = Provider<List<Lancamento>>((ref) {
  final todos = ref.watch(lancamentosStreamProvider).value ?? [];
  final hoje = DateTime.now();
  final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
  return todos
      .where((l) =>
          l.tipo != TipoLancamento.receita &&
          l.vencimento != null &&
          !l.vencimento!.isBefore(inicioHoje))
      .toList()
    ..sort((a, b) => a.vencimento!.compareTo(b.vencimento!));
});