import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/application/saudacao.dart';
import '../../investimentos/domain/investimento.dart';
import '../../lancamentos/domain/lancamento.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../../open_finance/domain/conta_bancaria_conectada.dart';
import '../../open_finance/domain/saldo_nas_contas.dart';

/// Números do cliente que o Guia de investimentos usa: só totais e médias, em
/// reais — nenhuma descrição de lançamento vai para a IA.
class DadosConsultoria {
  const DadosConsultoria({
    required this.meses,
    required this.mesParcial,
    required this.receitaMediaCents,
    required this.despesaMediaCents,
    required this.categoriasMedias,
    required this.investimentos,
    this.saldoContas,
    this.faturasAbertasCents,
  });

  /// Meses da média, do mais antigo ao mais recente.
  final List<DateTime> meses;

  /// Sem mês completo com lançamentos: a média é o mês atual até agora.
  final bool mesParcial;

  final int receitaMediaCents;
  final int despesaMediaCents;

  /// Despesa média por categoria, da maior para a menor.
  final List<GastoCategoria> categoriasMedias;

  final List<Investimento> investimentos;

  /// Saldo das contas dos bancos conectados (null sem banco conectado).
  final SaldoNasContas? saldoContas;

  /// Faturas de cartão em aberto (null se nenhum banco informou).
  final int? faturasAbertasCents;

  int get sobraMediaCents => receitaMediaCents - despesaMediaCents;

  int get investidoCents =>
      investimentos.fold(0, (s, i) => s + i.patrimonioCents);

  /// Dinheiro de fácil acesso, aproximado: contas + renda fixa + banco
  /// digital (ações, FIIs e cripto oscilam e ficam de fora).
  int get reservaCents =>
      (saldoContas?.totalCents ?? 0) +
      investimentos
          .where((i) => !i.ePorQuantidade)
          .fold(0, (s, i) => s + i.patrimonioCents);

  /// Quantos meses de despesas a reserva cobre (null sem despesa conhecida).
  double? get mesesDeReserva =>
      despesaMediaCents > 0 ? reservaCents / despesaMediaCents : null;

  bool get semDados =>
      meses.isEmpty && investimentos.isEmpty && saldoContas == null;

  String paraPrompt() {
    final linhas = <String>[];

    if (meses.isEmpty) {
      linhas.add('Fluxo mensal: nenhum lançamento registrado.');
    } else {
      final periodo = mesParcial
          ? 'mês atual até agora, ${mesPorExtenso(meses.single)} (parcial)'
          : meses.length == 1
              ? 'média de ${mesPorExtenso(meses.single)}'
              : 'média de ${mesPorExtenso(meses.first)} a '
                  '${mesPorExtenso(meses.last)}, ${meses.length} meses';
      final pctSobra = receitaMediaCents > 0
          ? ' (${(sobraMediaCents / receitaMediaCents * 100).round()}% '
              'da renda)'
          : '';
      linhas
        ..add('Fluxo mensal ($periodo):')
        ..add('- Receitas: ${formatoBRL(receitaMediaCents)} por mês')
        ..add('- Despesas: ${formatoBRL(despesaMediaCents)} por mês')
        ..add('- Sobra: ${formatoBRL(sobraMediaCents)} por mês$pctSobra');
      if (categoriasMedias.isNotEmpty) {
        linhas.add('Maiores despesas por categoria (por mês):');
        for (final c in categoriasMedias) {
          linhas.add('- ${c.categoria}: ${formatoBRL(c.valorCents)}');
        }
      }
    }

    final saldo = saldoContas;
    if (saldo == null) {
      linhas.add('Bancos conectados: nenhum (saldo em conta desconhecido).');
    } else {
      linhas.add('Saldo nas contas dos bancos conectados: '
          '${formatoBRL(saldo.totalCents)} '
          '(atualizado em ${formatoData(saldo.atualizadoEm)})');
    }
    final faturas = faturasAbertasCents;
    if (faturas != null) {
      linhas.add('Faturas de cartão em aberto: ${formatoBRL(faturas)}');
    }

    if (investimentos.isEmpty) {
      linhas.add('Investimentos: nenhum registrado.');
    } else {
      linhas.add('Investimentos (vindos do banco): '
          '${formatoBRL(investidoCents)} no total');
      for (final classe in TipoClasseInvestimento.values) {
        final daClasse = investimentos.where((i) => i.classe == classe).toList()
          ..sort((a, b) => b.patrimonioCents.compareTo(a.patrimonioCents));
        if (daClasse.isEmpty) continue;
        final total = daClasse.fold(0, (s, i) => s + i.patrimonioCents);
        final ativos = daClasse.take(_maxAtivosPorClasse).map(_ativo).join('; ');
        final resto = daClasse.length - _maxAtivosPorClasse;
        linhas.add('- ${classe.rotulo}: ${formatoBRL(total)} — $ativos'
            '${resto > 0 ? '; e mais $resto' : ''}');
      }
    }

    final cobertura = mesesDeReserva;
    linhas.add('Reserva de fácil acesso aproximada (contas + renda fixa + '
        'banco digital): ${formatoBRL(reservaCents)}'
        '${cobertura == null ? '' : ' = ${cobertura.toStringAsFixed(1).replaceAll('.', ',')} '
            'meses das despesas médias'}');

    return linhas.join('\n');
  }

  static const int _maxAtivosPorClasse = 6;

  static String _ativo(Investimento i) {
    final nome = i.nome.length > 40 ? '${i.nome.substring(0, 40)}…' : i.nome;
    final pct = i.rentabilidadePercent;
    final rend = pct == null
        ? ''
        : ' (${pct >= 0 ? '+' : ''}'
            '${pct.toStringAsFixed(1).replaceAll('.', ',')}% desde a aplicação)';
    return '$nome ${formatoBRL(i.patrimonioCents)}$rend';
  }
}

/// Monta os [DadosConsultoria]: média dos últimos [quantidadeMeses] meses
/// completos que têm lançamentos (sem nenhum, o mês atual até [hoje]).
DadosConsultoria montarDadosConsultoria({
  required List<Lancamento> lancamentos,
  required List<Investimento> investimentos,
  required List<ContaBancariaConectada> contas,
  required DateTime hoje,
  int quantidadeMeses = 3,
}) {
  bool temMovimento(ResumoMes r) => r.entradasCents != 0 || r.saidasCents != 0;

  var meses = <DateTime>[];
  final resumos = <ResumoMes>[];
  for (var i = quantidadeMeses; i >= 1; i--) {
    final mes = DateTime(hoje.year, hoje.month - i);
    final resumo = resumoDoMes(lancamentos, mes);
    if (!temMovimento(resumo)) continue;
    meses.add(mes);
    resumos.add(resumo);
  }

  var parcial = false;
  if (meses.isEmpty) {
    final atual = DateTime(hoje.year, hoje.month);
    final resumo = resumoDoMes(lancamentos, atual);
    if (temMovimento(resumo)) {
      meses = [atual];
      resumos.add(resumo);
      parcial = true;
    }
  }

  final n = meses.length;
  int media(int total) => n == 0 ? 0 : (total / n).round();

  final porCategoria = <String, int>{};
  for (final l in lancamentos) {
    if (l.ehMovimentacaoNeutra) continue;
    final valor = l.valorDespesaCents;
    if (valor == 0) continue;
    final noPeriodo =
        meses.any((m) => m.year == l.data.year && m.month == l.data.month);
    if (!noPeriodo) continue;
    porCategoria.update(l.categoria, (v) => v + valor, ifAbsent: () => valor);
  }
  final categorias = porCategoria.entries
      .map((e) => GastoCategoria(categoria: e.key, valorCents: media(e.value)))
      .where((g) => g.valorCents > 0)
      .toList()
    ..sort((a, b) => b.valorCents.compareTo(a.valorCents));

  final comFatura = contas.where((c) => c.faturaCartoesCents != null);

  return DadosConsultoria(
    meses: meses,
    mesParcial: parcial,
    receitaMediaCents: media(resumos.fold(0, (s, r) => s + r.entradasCents)),
    despesaMediaCents: media(resumos.fold(0, (s, r) => s + r.saidasCents)),
    categoriasMedias: categorias.take(6).toList(),
    investimentos: investimentos,
    saldoContas: saldoNasContas(contas),
    faturasAbertasCents: comFatura.isEmpty
        ? null
        : comFatura.fold<int>(0, (s, c) => s + c.faturaCartoesCents!),
  );
}
