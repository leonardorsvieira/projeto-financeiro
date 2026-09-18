import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../lancamentos/application/exportar_service.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../application/pdf_report_service.dart';
import '../application/relatorios_providers.dart';
import 'widgets/comparativo_mensal_chart.dart';
import 'widgets/evolucao_patrimonial_chart.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final numMeses = ref.watch(numMesesRelatorioProvider);
    final dados = ref.watch(relatoriosComparativosProvider);
    final lancamentos = ref.watch(lancamentosStreamProvider).value ?? [];

    final fmtBrl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
    final isPositivo = dados.variacaoPatrimonialPercent >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios & Comparativos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportarPDF(context, dados, lancamentos),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Exportar Excel (CSV)',
            onPressed: () => _exportarCSV(context, dados),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Seletor de Período
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período de Análise',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 6,
                          label: Text('Últimos 6 Meses'),
                          icon: Icon(Icons.calendar_view_month),
                        ),
                        ButtonSegment(
                          value: 12,
                          label: Text('Últimos 12 Meses'),
                          icon: Icon(Icons.calendar_today),
                        ),
                      ],
                      selected: {numMeses},
                      onSelectionChanged: (val) {
                        ref
                            .read(numMesesRelatorioProvider.notifier)
                            .setMeses(val.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Evolução Patrimonial (Linha do Tempo)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evolução Patrimonial',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Patrimônio Líquido Acumulado',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPositivo
                              ? Colors.green.shade100
                              : theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositivo
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: isPositivo
                                  ? Colors.green.shade800
                                  : theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dados.variacaoPatrimonialPercent >= 0 ? "+" : ""}${dados.variacaoPatrimonialPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPositivo
                                    ? Colors.green.shade800
                                    : theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ValorResumoItem(
                        rotulo: 'Patrimônio Atual',
                        valor: fmtBrl.format(dados.patrimonioAtualCents / 100),
                        cor: theme.colorScheme.primary,
                      ),
                      _ValorResumoItem(
                        rotulo: 'Patrimônio Inicial',
                        valor:
                            fmtBrl.format(dados.patrimonioInicialCents / 100),
                        cor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  EvolucaoPatrimonialChart(pontos: dados.pontos),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Comparativo Mensal (Entradas vs Saídas)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparativo Mensal (Entradas vs Saídas)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Receita vs Despesa mês a mês',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ValorResumoItem(
                        rotulo: 'Média de Receita',
                        valor: fmtBrl.format(dados.mediaEntradasReais),
                        cor: Colors.green.shade700,
                      ),
                      _ValorResumoItem(
                        rotulo: 'Média de Despesa',
                        valor: fmtBrl.format(dados.mediaSaidasReais),
                        cor: theme.colorScheme.error,
                      ),
                      _ValorResumoItem(
                        rotulo: 'Saldo do Período',
                        valor: fmtBrl.format(dados.saldoTotalCents / 100),
                        cor: dados.saldoTotalCents >= 0
                            ? Colors.green.shade700
                            : theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ComparativoMensalChart(pontos: dados.pontos),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Ações de Exportação
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.download_outlined, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exportar Relatórios',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gere arquivos em PDF formatado ou planilha Excel (CSV).',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _exportarPDF(context, dados, lancamentos),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exportar PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _exportarCSV(context, dados),
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('Excel (CSV)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportarPDF(
    BuildContext context,
    DadosRelatorioComparativo dados,
    List<dynamic> lancamentos,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando relatório em PDF...')),
    );
    await PdfReportService.gerarECompartilharPDF(
      dados: dados,
      lancamentos: lancamentos.cast(),
    );
  }

  void _exportarCSV(
    BuildContext context,
    DadosRelatorioComparativo dados,
  ) async {
    final csvContent = ExportarService.gerarCSVComparativo(dados);
    final bytes = Uint8List.fromList(csvContent.codeUnits);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'MeuBolso_Comparativo_Mensal.csv',
    );
  }
}

class _ValorResumoItem extends StatelessWidget {
  const _ValorResumoItem({
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
