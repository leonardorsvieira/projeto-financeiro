import '../../lancamentos/domain/lancamento_converter.dart';
import 'dashboard_providers.dart';
import 'saudacao.dart';

/// Nenhum número no mês: não há o que a IA analisar.
bool mesSemLancamentos(ResumoMes resumo, List<GastoCategoria> gastos) =>
    gastos.isEmpty &&
    resumo.entradasCents == 0 &&
    resumo.saidasCents == 0 &&
    resumo.previstoCents == 0 &&
    resumo.resgatesCents == 0 &&
    resumo.aplicacoesCents == 0;

/// Números de [mes] que vão para a "Análise do mês (IA)": só deste mês e em
/// reais. Centavos crus ("saídas: 350000") a IA lia como R$ 350.000, o que
/// parecia a soma de vários meses.
String dadosAnaliseDoMes({
  required ResumoMes resumo,
  required List<GastoCategoria> gastos,
  required DateTime mes,
  required DateTime hoje,
}) {
  final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
  final String situacao;
  if (mes.year == hoje.year && mes.month == hoje.month) {
    situacao = 'mês em andamento: dia ${hoje.day} de $ultimoDia, '
        'os números ainda são parciais';
  } else if (DateTime(mes.year, mes.month).isAfter(hoje)) {
    situacao = 'mês futuro: só lançamentos já agendados';
  } else {
    situacao = 'mês encerrado';
  }

  final linhas = <String>[
    'Mês analisado: ${mesPorExtenso(mes)} ($situacao).',
    'Receitas do mês: ${formatoBRL(resumo.entradasCents)}',
    'Despesas do mês: ${formatoBRL(resumo.saidasCents)}',
    'Saldo do mês: ${formatoBRL(resumo.saldoCents)}',
    if (resumo.resgatesCents > 0)
      'Resgatado de investimentos (entra no saldo, não é receita): '
          '${formatoBRL(resumo.resgatesCents)}',
    if (resumo.aplicacoesCents > 0)
      'Aplicado em investimentos (sai do saldo, não é despesa): '
          '${formatoBRL(resumo.aplicacoesCents)}',
    if (resumo.previstoCents > 0)
      'Contas que vencem no mês e ainda não foram pagas: '
          '${formatoBRL(resumo.previstoCents)}',
  ];

  final total = gastos.fold(0, (s, g) => s + g.valorCents);
  if (gastos.isEmpty) {
    linhas.add('Despesas por categoria: nenhuma.');
  } else {
    linhas.add('Despesas por categoria (da maior para a menor):');
    for (final g in gastos) {
      final pct = total > 0 ? (g.valorCents / total * 100).round() : 0;
      linhas.add('- ${g.categoria}: ${formatoBRL(g.valorCents)} '
          '($pct% das despesas)');
    }
  }
  return linhas.join('\n');
}
