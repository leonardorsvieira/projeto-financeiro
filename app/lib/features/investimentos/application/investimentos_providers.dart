import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_investimentos_repository.dart';
import '../data/supabase_movimentos_investimento_repository.dart';
import '../data/supabase_rendimentos_investimento_repository.dart';
import '../domain/investimento.dart';
import '../domain/investimentos_repository.dart';
import '../domain/movimento_investimento.dart';
import '../domain/movimentos_investimento_repository.dart';
import '../domain/rendimento_investimento.dart';
import '../domain/rendimentos_investimento_repository.dart';

final investimentosRepositoryProvider = Provider<InvestimentosRepository>(
  (ref) => SupabaseInvestimentosRepository(),
);

final investimentosStreamProvider = StreamProvider<List<Investimento>>((ref) {
  return ref.watch(investimentosRepositoryProvider).watch();
});

final movimentosInvestimentoRepositoryProvider =
    Provider<MovimentosInvestimentoRepository>(
  (ref) => SupabaseMovimentosInvestimentoRepository(),
);

final movimentosPorInvestimentoProvider =
    StreamProvider.family<List<MovimentoInvestimento>, String>((ref, id) {
  return ref.watch(movimentosInvestimentoRepositoryProvider)
      .watchPorInvestimento(id);
});

final rendimentosInvestimentoRepositoryProvider =
    Provider<RendimentosInvestimentoRepository>(
  (ref) => SupabaseRendimentosInvestimentoRepository(),
);

final rendimentosStreamProvider =
    StreamProvider<List<RendimentoInvestimento>>((ref) {
  return ref.watch(rendimentosInvestimentoRepositoryProvider).watchTodos();
});

final rendimentosPorAtivoProvider =
    Provider.family<List<RendimentoInvestimento>, String>((ref, id) {
  final todos = ref.watch(rendimentosStreamProvider).value ?? [];
  return todos.where((r) => r.investimentoId == id).toList();
});

/// Patrimônio total somando todos os ativos (qtd×preço ou saldo).
final patrimonioTotalProvider = Provider<int>((ref) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  return investimentos.fold(
    0,
    (sum, inv) => sum + inv.patrimonioCents,
  );
});

/// Custo investido por ativo = Σ compras − Σ vendas (qtd×preço).
/// Para RF/bco a quantidade é 1 e o preço é o valor aplicado/resgatado.
final custoPorAtivoProvider = Provider<Map<String, int>>((ref) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  final custo = <String, int>{};
  for (final inv in investimentos) {
    final movs =
        ref.watch(movimentosPorInvestimentoProvider(inv.id)).value ?? [];
    var total = 0;
    for (final m in movs) {
      final sinal = m.tipo == TipoMovimentoInvestimento.compra ? 1 : -1;
      total += sinal * m.valorCents;
    }
    custo[inv.id] = total;
  }
  return custo;
});

/// Custo total investido (soma de custoPorAtivoProvider).
final custoTotalProvider = Provider<int>((ref) {
  final custo = ref.watch(custoPorAtivoProvider);
  return custo.values.fold(0, (sum, v) => sum + v);
});

/// Rendimento acumulado total = patrimônio total − custo total.
final rendimentoAcumuladoProvider = Provider<int>((ref) {
  final patrimonio = ref.watch(patrimonioTotalProvider);
  final custo = ref.watch(custoTotalProvider);
  return patrimonio - custo;
});

/// Ordem fixa de exibição das classes na lista.
const ordemClassesInvestimento = [
  TipoClasseInvestimento.rendaFixa,
  TipoClasseInvestimento.bancoDigital,
  TipoClasseInvestimento.acao,
  TipoClasseInvestimento.fii,
  TipoClasseInvestimento.cripto,
];

/// Investimentos agrupados por classe, na ordem fixa de exibição.
class InvestimentosPorClasse {
  const InvestimentosPorClasse(this.grupos);

  final List<GrupoInvestimento> grupos;

  int get totalAtivos =>
      grupos.fold(0, (acc, g) => acc + g.investimentos.length);
}

class GrupoInvestimento {
  const GrupoInvestimento({required this.classe, required this.investimentos});

  final TipoClasseInvestimento classe;
  final List<Investimento> investimentos;
}

final investimentosPorClasseProvider =
    Provider<InvestimentosPorClasse>((ref) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];

  final grupos = <GrupoInvestimento>[];
  for (final classe in ordemClassesInvestimento) {
    final doGrupo = investimentos.where((i) => i.classe == classe).toList();
    if (doGrupo.isEmpty) continue;
    grupos.add(GrupoInvestimento(classe: classe, investimentos: doGrupo));
  }
  return InvestimentosPorClasse(grupos);
});

/// Rendimentos de um mês (chave 'ano-mes'), agregados.
class MesRendimentos {
  const MesRendimentos({
    required this.ano,
    required this.mes,
    required this.rendimentos,
  });

  final int ano;
  final int mes;
  final List<RendimentoInvestimento> rendimentos;

  int get totalCents =>
      rendimentos.fold(0, (soma, r) => soma + r.valorCents);
}

/// Rendimentos agregados por mês, do mais recente para o mais antigo.
final rendimentosPorMesProvider = Provider<List<MesRendimentos>>((ref) {
  final todos = ref.watch(rendimentosStreamProvider).value ?? [];
  final porMes = <String, List<RendimentoInvestimento>>{};
  for (final r in todos) {
    final chave =
        '${r.data.year}-${r.data.month.toString().padLeft(2, '0')}';
    porMes.putIfAbsent(chave, () => []).add(r);
  }

  final meses = porMes.entries.map((e) {
    final partes = e.key.split('-');
    return MesRendimentos(
      ano: int.parse(partes[0]),
      mes: int.parse(partes[1]),
      rendimentos: e.value,
    );
  }).toList()
    ..sort((a, b) {
      final porAno = a.ano.compareTo(b.ano);
      return porAno != 0 ? porAno : a.mes.compareTo(b.mes);
    });
  return meses.reversed.toList();
});
