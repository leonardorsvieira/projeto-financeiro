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