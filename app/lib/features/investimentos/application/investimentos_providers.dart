import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return ref
          .watch(movimentosInvestimentoRepositoryProvider)
          .watchPorInvestimento(id);
    });

final rendimentosInvestimentoRepositoryProvider =
    Provider<RendimentosInvestimentoRepository>(
      (ref) => SupabaseRendimentosInvestimentoRepository(),
    );

final rendimentosStreamProvider = StreamProvider<List<RendimentoInvestimento>>((
  ref,
) {
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
  return investimentos.fold(0, (sum, inv) => sum + inv.patrimonioCents);
});

/// Quanto foi aplicado, quanto vale hoje e quanto rendeu — no total e por
/// ativo. Só entram na conta os ativos cujo banco informou o valor aplicado
/// ([semValorInvestido] conta os demais).
class ResumoRendimentos {
  const ResumoRendimentos({
    required this.investidoCents,
    required this.atualCents,
    required this.ranking,
    required this.semValorInvestido,
  });

  factory ResumoRendimentos.de(List<Investimento> investimentos) {
    final comDado =
        investimentos.where((i) => i.valorInvestidoCents != null).toList()
          ..sort((a, b) => b.rendimentoCents!.compareTo(a.rendimentoCents!));
    return ResumoRendimentos(
      investidoCents: comDado.fold(0, (s, i) => s + i.valorInvestidoCents!),
      atualCents: comDado.fold(0, (s, i) => s + i.patrimonioCents),
      ranking: comDado,
      semValorInvestido: investimentos.length - comDado.length,
    );
  }

  /// Soma do valor aplicado.
  final int investidoCents;

  /// Valor atual desses mesmos ativos.
  final int atualCents;

  /// Ativos com valor aplicado, do que mais rendeu ao que mais perdeu (R$).
  final List<Investimento> ranking;

  final int semValorInvestido;

  int get rendimentoCents => atualCents - investidoCents;

  double? get rentabilidadePercent =>
      investidoCents == 0 ? null : rendimentoCents / investidoCents * 100;

  /// O que mais rendeu (null se nenhum teve ganho).
  Investimento? get maiorGanho =>
      ranking.isNotEmpty && ranking.first.rendimentoCents! > 0
      ? ranking.first
      : null;

  /// O que mais perdeu (null se nenhum teve perda).
  Investimento? get maiorPerda =>
      ranking.isNotEmpty && ranking.last.rendimentoCents! < 0
      ? ranking.last
      : null;
}

final resumoRendimentosProvider = Provider<ResumoRendimentos>((ref) {
  final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
  return ResumoRendimentos.de(investimentos);
});

/// Rendimento total (valor atual − valor aplicado) dos ativos com dado.
final rendimentoAcumuladoProvider = Provider<int>(
  (ref) => ref.watch(resumoRendimentosProvider).rendimentoCents,
);

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

final investimentosPorClasseProvider = Provider<InvestimentosPorClasse>((ref) {
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

  int get totalCents => rendimentos.fold(0, (soma, r) => soma + r.valorCents);
}

/// Rendimentos agregados por mês, do mais recente para o mais antigo.
final rendimentosPorMesProvider = Provider<List<MesRendimentos>>((ref) {
  final todos = ref.watch(rendimentosStreamProvider).value ?? [];
  final porMes = <String, List<RendimentoInvestimento>>{};
  for (final r in todos) {
    final chave = '${r.data.year}-${r.data.month.toString().padLeft(2, '0')}';
    porMes.putIfAbsent(chave, () => []).add(r);
  }

  final meses =
      porMes.entries.map((e) {
        final partes = e.key.split('-');
        return MesRendimentos(
          ano: int.parse(partes[0]),
          mes: int.parse(partes[1]),
          rendimentos: e.value,
        );
      }).toList()..sort((a, b) {
        final porAno = a.ano.compareTo(b.ano);
        return porAno != 0 ? porAno : a.mes.compareTo(b.mes);
      });
  return meses.reversed.toList();
});

/// Metas percentuais de alocação por classe de investimento.
final metasAlocacaoProvider =
    NotifierProvider<
      MetasAlocacaoNotifier,
      Map<TipoClasseInvestimento, double>
    >(MetasAlocacaoNotifier.new);

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
    Map<TipoClasseInvestimento, double> novasMetas,
  ) async {
    state = novasMetas;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in novasMetas.entries) {
      await prefs.setDouble('meta_alocacao_${entry.key.dbValue}', entry.value);
    }
  }
}

/// Sugestões de rebalanceamento da carteira para um determinado valor de aporte em cents.
final rebalanceamentoSugestoesProvider =
    Provider.family<List<SugestaoAporteClasse>, int>((ref, aporteCents) {
      final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
      final metas = ref.watch(metasAlocacaoProvider);
      return InvestimentosCalculosService.calcularRebalanceamento(
        investimentos: investimentos,
        metasPercentuais: metas,
        aporteCents: aporteCents,
      );
    });
