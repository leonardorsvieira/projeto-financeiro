import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/dashboard_providers.dart';
import '../data/supabase_metas_repository.dart';
import '../domain/meta.dart';
import '../domain/metas_repository.dart';

final metasRepositoryProvider = Provider<MetasRepository>(
  (ref) => SupabaseMetasRepository(),
);

final metasStreamProvider = StreamProvider<List<Meta>>((ref) {
  return ref.watch(metasRepositoryProvider).watch();
});

/// Meta combinada com o gasto do mês vigente da categoria e o % de uso.
class MetaComProgresso {
  const MetaComProgresso({
    required this.meta,
    required this.gastoCents,
  });

  final Meta meta;
  final int gastoCents;

  int get percentual {
    if (meta.valorLimiteCents <= 0) return 0;
    return (gastoCents / meta.valorLimiteCents * 100).round();
  }

  bool get estourou => percentual > 100;
  bool get quaseEstourada => percentual >= 80 && !estourou;
}

final metasComProgressoProvider = Provider<List<MetaComProgresso>>((ref) {
  final metas = ref.watch(metasStreamProvider).value ?? [];
  final gastos = ref.watch(gastosPorCategoriaMesProvider);
  final gastoPorCategoria = {for (final g in gastos) g.categoria: g.valorCents};

  return [
    for (final meta in metas)
      MetaComProgresso(
        meta: meta,
        gastoCents: gastoPorCategoria[meta.categoria] ?? 0,
      ),
  ];
});