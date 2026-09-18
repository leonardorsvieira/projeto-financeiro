import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/relatorios_providers.dart';

class EvolucaoPatrimonialChart extends StatelessWidget {
  const EvolucaoPatrimonialChart({
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

    if (pontos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem dados suficientes para o período.')),
      );
    }

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < pontos.length; i++) {
      final val = pontos[i].patrimonioAcumuladoReais;
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    // Margem vertical para os limites do gráfico
    final rangeY = (maxY - minY).abs();
    final paddingY = rangeY == 0 ? 100.0 : rangeY * 0.15;
    final chartMinY = minY - paddingY;
    final chartMaxY = maxY + paddingY;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
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
                interval: 1,
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
          minX: 0,
          maxX: (pontos.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainerHighest,
              getTooltipItems: (touchedSpots) {
                final fmtFull = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx >= 0 && idx < pontos.length) {
                    final p = pontos[idx];
                    final dataStr = '${_siglasMeses[p.mesAno.month - 1]}/${p.mesAno.year}';
                    return LineTooltipItem(
                      '$dataStr\n',
                      theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: fmtFull.format(p.patrimonioAcumuladoReais),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: theme.colorScheme.primary,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
