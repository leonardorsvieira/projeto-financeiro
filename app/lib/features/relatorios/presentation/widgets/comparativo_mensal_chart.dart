import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/relatorios_providers.dart';

class ComparativoMensalChart extends StatelessWidget {
  const ComparativoMensalChart({
    super.key,
    required this.pontos,
  });

  final List<PontoHistoricoMes> pontos;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtBrl = NumberFormat.compactSimpleCurrency(locale: 'pt_BR');
    final fmtFull = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');

    if (pontos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem dados no período selecionado.')),
      );
    }

    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < pontos.length; i++) {
      final p = pontos[i];
      final e = p.entradasReais;
      final s = p.saidasReais;

      if (e > maxY) maxY = e;
      if (s > maxY) maxY = s;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: e,
              color: Colors.green.shade600,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: s,
              color: theme.colorScheme.error,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final chartMaxY = maxY == 0 ? 1000.0 : maxY * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IndicadorLegenda(
              cor: Colors.green.shade600,
              rotulo: 'Entradas (Receitas)',
            ),
            const SizedBox(width: 24),
            _IndicadorLegenda(
              cor: theme.colorScheme.error,
              rotulo: 'Saídas (Despesas)',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < pontos.length) {
                        final mes = pontos[idx].mesAno;
                        final text = _siglasMeses[mes.month - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            text,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        fmtBrl.format(value),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      theme.colorScheme.surfaceContainerHighest,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final p = pontos[groupIndex];
                    final isReceita = rodIndex == 0;
                    final tipo = isReceita ? 'Entrada' : 'Saída';
                    final valor = isReceita ? p.entradasReais : p.saidasReais;
                    final mesStr =
                        '${_siglasMeses[p.mesAno.month - 1]}/${p.mesAno.year}';
                    return BarTooltipItem(
                      '$mesStr ($tipo)\n',
                      theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: fmtFull.format(valor),
                          style: TextStyle(
                            color: isReceita
                                ? Colors.green.shade700
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IndicadorLegenda extends StatelessWidget {
  const _IndicadorLegenda({
    required this.cor,
    required this.rotulo,
  });

  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rotulo,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
