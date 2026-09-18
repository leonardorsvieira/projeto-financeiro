import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../home/domain/app_routes.dart';
import '../application/investimentos_providers.dart';
import '../domain/rendimento_investimento.dart';

class CalendarioProventosScreen extends ConsumerWidget {
  const CalendarioProventosScreen({super.key});

  static const _siglasMeses = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  static const _mesesExtenso = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rendimentosMeses = ref.watch(rendimentosPorMesProvider);
    final todosRendimentos = ref.watch(rendimentosStreamProvider).value ?? [];
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];

    final fmtBrl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
    final fmtBrlCompact = NumberFormat.compactSimpleCurrency(locale: 'pt_BR');
    final fmtData = DateFormat('dd/MM/yyyy');

    final mapaInvestimentos = {for (final i in investimentos) i.id: i};

    int totalAcumuladoCents = 0;
    for (final r in todosRendimentos) {
      totalAcumuladoCents += r.valorCents;
    }

    final mediaMensalReais = rendimentosMeses.isEmpty
        ? 0.0
        : (totalAcumuladoCents / 100.0) / rendimentosMeses.length;

    // Prepara dados para o gráfico de proventos por mês (últimos 6 a 12 meses)
    final ultimosMeses = rendimentosMeses.take(6).toList().reversed.toList();
    double maxProvento = 0;
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < ultimosMeses.length; i++) {
      final m = ultimosMeses[i];
      final valReais = m.totalCents / 100.0;
      if (valReais > maxProvento) maxProvento = valReais;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valReais,
              color: Colors.green.shade600,
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final chartMaxY = maxProvento == 0 ? 100.0 : maxProvento * 1.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Proventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Ver Todos os Rendimentos',
            onPressed: () => context.push(AppRoutes.rendimentos),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de Resumo
          Card(
            color: Colors.green.shade50,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricItem(
                    rotulo: 'Total Recebido',
                    valor: fmtBrl.format(totalAcumuladoCents / 100.0),
                    cor: Colors.green.shade800,
                  ),
                  _MetricItem(
                    rotulo: 'Média Mensal',
                    valor: fmtBrl.format(mediaMensalReais),
                    cor: Colors.green.shade700,
                  ),
                  _MetricItem(
                    rotulo: 'Meses com Proventos',
                    valor: '${rendimentosMeses.length}',
                    cor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gráfico de Proventos Recentes
          if (ultimosMeses.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolução dos Proventos Recentes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.8,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: chartMaxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              dashArray: [4, 4],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < ultimosMeses.length) {
                                    final m = ultimosMeses[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${_siglasMeses[m.mes - 1]}/${m.ano.toString().substring(2)}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) => Text(
                                  fmtBrlCompact.format(value),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(fontSize: 9),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lista por Mês
          Text(
            'Histórico Mês a Mês',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (rendimentosMeses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nenhum provento cadastrado ainda.'),
                ),
              ),
            )
          else
            for (final mes in rendimentosMeses) ...[
              Card(
                child: ExpansionTile(
                  title: Text(
                    '${_mesesExtenso[mes.mes - 1]} ${mes.ano}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    fmtBrl.format(mes.totalCents / 100.0),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  children: [
                    for (final r in mes.rendimentos) ...[
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            _getIconForTipo(r.tipo),
                            size: 16,
                            color: Colors.green.shade800,
                          ),
                        ),
                        title: Text(
                          mapaInvestimentos[r.investimentoId]?.nome ??
                              'Ativo Não Identificado',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${r.tipo.rotulo} • ${fmtData.format(r.data)}',
                        ),
                        trailing: Text(
                          '+ ${fmtBrl.format(r.valorCents / 100.0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  IconData _getIconForTipo(TipoRendimentoInvestimento tipo) {
    switch (tipo) {
      case TipoRendimentoInvestimento.dividendo:
        return Icons.attach_money;
      case TipoRendimentoInvestimento.juros:
        return Icons.percent;
      case TipoRendimentoInvestimento.rendimento:
        return Icons.trending_up;
      case TipoRendimentoInvestimento.outro:
        return Icons.payments_outlined;
    }
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
}
