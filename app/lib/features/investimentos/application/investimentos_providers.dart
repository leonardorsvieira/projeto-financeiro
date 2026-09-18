import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cotacoes_service.dart';
import '../data/supabase_investimentos_repository.dart';
import '../data/supabase_movimentos_investimento_repository.dart';
import '../data/supabase_rendimentos_investimento_repository.dart';
import '../domain/investimento.dart';
import '../domain/investimentos_repository.dart';
import '../domain/movimento_investimento.dart';
import '../domain/movimentos_investimento_repository.dart';
import '../domain/rendimento_investimento.dart';
import '../domain/rendimentos_investimento_repository.dart';
import 'investimentos_calculos_service.dart';

final cotacoesServiceProvider = Provider<CotacoesService>(
  (ref) => CotacoesService(),
);

final investimentosRepositoryProvider = Provider<InvestimentosRepository>(
  (ref) => SupabaseInvestimentosRepository(),
);

/// Provider para atualizar todas as cotações dos ativos por quantidade.
final atualizarCotacoesProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.read(cotacoesServiceProvider);
  final repo = ref.read(investimentosRepositoryProvider);
  final investimentos = ref.read(investimentosStreamProvider).value ?? [];

  final ativosPorQtd = investimentos.where((i) => i.ePorQuantidade).toList();
  if (ativosPorQtd.isEmpty) return 0;

  var atualizados = 0;
  for (final inv in ativosPorQtd) {
    final novoPreco = await service.buscarPrecoCents(inv.nome, inv.classe);
    if (novoPreco != null && novoPreco > 0) {
      if (novoPreco != inv.precoAtualCents) {
        await repo.update(
          Investimento(
            id: inv.id,
            classe: inv.classe,
            nome: inv.nome,
            quantidade: inv.quantidade,
            precoAtualCents: novoPreco,
            saldoCents: inv.saldoCents,
          ),
        );
        atualizados++;
      }
    }
  }
  return atualizados;
});

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

/// Preço Médio (PM) e Rentabilidade apurada por ativo.
final precoMedioPorAtivoProvider =
    Provider.family<PrecoMedioResultado?, String>((ref, id) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  final investimento =
      investimentos.where((i) => i.id == id).firstOrNull;
  if (investimento == null) return null;

  final movs = ref.watch(movimentosPorInvestimentoProvider(id)).value ?? [];
  return InvestimentosCalculosService.calcularPrecoMedio(
    investimento: investimento,
    movimentos: movs,
  );
});

/// Metas percentuais de alocação por classe de investimento.
final metasAlocacaoProvider = NotifierProvider<MetasAlocacaoNotifier,
    Map<TipoClasseInvestimento, double>>(
  MetasAlocacaoNotifier.new,
);

class MetasAlocacaoNotifier
    extends Notifier<Map<TipoClasseInvestimento, double>> {
  @override
  Map<TipoClasseInvestimento, double> build() {
    _carregarPrefs();
    return const {
      TipoClasseInvestimento.rendaFixa: 40.0,
      TipoClasseInvestimento.bancoDigital: 10.0,
      TipoClasseInvestimento.acao: 30.0,
      TipoClasseInvestimento.fii: 15.0,
      TipoClasseInvestimento.cripto: 5.0,
    };
  }

  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final metas = <TipoClasseInvestimento, double>{};
    for (final classe in TipoClasseInvestimento.values) {
      final key = 'meta_alocacao_${classe.dbValue}';
      if (prefs.containsKey(key)) {
        metas[classe] = prefs.getDouble(key) ?? 0.0;
      } else {
        metas[classe] = state[classe] ?? 0.0;
      }
    }
    state = metas;
  }

  Future<void> salvarMetas(
      Map<TipoClasseInvestimento, double> novasMetas) async {
    state = novasMetas;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in novasMetas.entries) {
      await prefs.setDouble('meta_alocacao_${entry.key.dbValue}', entry.value);
    }
  }
}

/// Sugestões de rebalanceamento da carteira para um determinado valor de aporte em cents.
final rebalanceamentoSugestoesProvider = Provider.family<
    List<SugestaoAporteClasse>, int>((ref, aporteCents) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  final metas = ref.watch(metasAlocacaoProvider);
  return InvestimentosCalculosService.calcularRebalanceamento(
    investimentos: investimentos,
    metasPercentuais: metas,
    aporteCents: aporteCents,
  );
});
