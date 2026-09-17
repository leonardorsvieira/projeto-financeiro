import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cartoes/application/cartoes_providers.dart';
import '../../cartoes/data/cartoes_repository.dart';
import '../../cartoes/domain/cartao_credito.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart';
import '../../lancamentos/domain/lancamento_converter.dart';

class RelatorioCartoesWidget extends ConsumerWidget {
  const RelatorioCartoesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lancamentosState = ref.watch(lancamentosStreamProvider);
    final cartoesState = ref.watch(cartoesControllerProvider);

    final List<Lancamento> lancamentos = lancamentosState.value ?? [];
    final List<CartaoCredito> cartoes = cartoesState.value ?? CartoesRepository.cartoesPadrao;

    final despesas =
        lancamentos.where((l) => l.tipo == TipoLancamento.despesa).toList();

    int totalPixCents = 0;
    final Map<String, int> totaisPorCartao = {};

    for (final c in cartoes) {
      totaisPorCartao[c.nome] = 0;
    }

    for (final d in despesas) {
      final fp = d.formaPagamento.toLowerCase();
      final int valCents = d.valorCents;
      if (fp.contains('pix') || fp.contains('débito') || fp.contains('dinheiro')) {
        totalPixCents = totalPixCents + valCents;
      } else {
        bool mapeado = false;
        for (final c in cartoes) {
          if (fp.contains(c.nome.toLowerCase())) {
            totaisPorCartao[c.nome] = (totaisPorCartao[c.nome] ?? 0) + valCents;
            mapeado = true;
            break;
          }
        }
        if (!mapeado) {
          final primeiroNome = cartoes.isNotEmpty ? cartoes.first.nome : 'Cartão';
          totaisPorCartao[primeiroNome] =
              (totaisPorCartao[primeiroNome] ?? 0) + valCents;
        }
      }
    }

    final totalGasto = totalPixCents +
        totaisPorCartao.values.fold<int>(0, (sum, val) => sum + val);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, color: Color(0xFF0B7A4B)),
                const SizedBox(width: 8),
                Text(
                  'Gastos por Meio de Pagamento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalGasto == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma despesa cadastrada neste mês.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      if (totalPixCents > 0)
                        PieChartSectionData(
                          color: const Color(0xFF32BCAD),
                          value: totalPixCents.toDouble(),
                          title:
                              '${((totalPixCents / totalGasto) * 100).toStringAsFixed(0)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ...totaisPorCartao.entries
                          .where((e) => e.value > 0)
                          .map((e) {
                        final c = cartoes.firstWhere(
                          (element) => element.nome == e.key,
                          orElse: () => cartoes.first,
                        );
                        Color color;
                        try {
                          color = Color(
                              int.parse(c.corHex.replaceFirst('#', '0xFF')));
                        } catch (_) {
                          color = theme.colorScheme.primary;
                        }

                        return PieChartSectionData(
                          color: color,
                          value: e.value.toDouble(),
                          title:
                              '${((e.value / totalGasto) * 100).toStringAsFixed(0)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF32BCAD),
                  radius: 12,
                  child: Icon(Icons.flash_on, size: 14, color: Colors.white),
                ),
                title: const Text('Acumulado Pix'),
                trailing: Text(
                  formatoBRL(totalPixCents),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final c in cartoes)
                if ((totaisPorCartao[c.nome] ?? 0) > 0)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: () {
                        try {
                          return Color(
                              int.parse(c.corHex.replaceFirst('#', '0xFF')));
                        } catch (_) {
                          return theme.colorScheme.primary;
                        }
                      }(),
                      radius: 12,
                      child:
                          const Icon(Icons.credit_card, size: 14, color: Colors.white),
                    ),
                    title: Text('Fatura ${c.nome}'),
                    subtitle: Text(
                        'Fecha dia ${c.diaFechamento} | Vence dia ${c.diaVencimento}'),
                    trailing: Text(
                      formatoBRL(totaisPorCartao[c.nome] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
