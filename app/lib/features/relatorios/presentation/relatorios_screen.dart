import '../../../theme/caderneta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../theme/icones.dart';
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
    final lancamentos = ref.watch(lancamentosContabeisProvider);

    final fmtBrl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
    final isPositivo = dados.variacaoPatrimonialPercent >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e comparativos'),
        actions: [
          IconButton(
            icon: const PhosphorIcon(Icones.pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportarPDF(context, dados, lancamentos),
          ),
          IconButton(
            icon: const PhosphorIcon(Icones.planilha),
            tooltip: 'Exportar planilha (CSV)',
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
                          icon: PhosphorIcon(Icones.periodoCurto),
                        ),
                        ButtonSegment(
                          value: 12,
                          label: Text('Últimos 12 Meses'),
                          icon: PhosphorIcon(Icones.periodoLongo),
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

          // 2. Evolução patrimonial (Linha do Tempo)
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
                            dados.patrimonioReal
                                ? 'Evolução patrimonial'
                                : 'Saldo acumulado',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dados.patrimonioReal
                                ? 'Contas + investimentos − faturas'
                                : 'Entradas − saídas no período. Conecte seus '
                                    'bancos para ver o patrimônio.',
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
                              ? Caderneta.corReceitaFundo(context)
                              : theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              isPositivo
                                  ? Icones.sobe
                                  : Icones.desce,
                              size: 16,
                              color: isPositivo
                                  ? Caderneta.corReceita(context)
                                  : theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dados.variacaoPatrimonialPercent >= 0 ? "+" : ""}${dados.variacaoPatrimonialPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPositivo
                                    ? Caderneta.corReceita(context)
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
                        rotulo: dados.patrimonioReal
                            ? 'Patrimônio atual'
                            : 'Saldo no período',
                        valor: fmtBrl.format(dados.patrimonioAtualCents / 100),
                        cor: theme.colorScheme.primary,
                      ),
                      _ValorResumoItem(
                        rotulo: dados.patrimonioReal
                            ? 'Patrimônio inicial'
                            : 'Saldo no 1º mês',
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

          // 3. Comparativo mensal (receitas e despesas)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparativo mensal (receitas e despesas)',
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
                        cor: Caderneta.corReceita(context),
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
                            ? Caderneta.corReceita(context)
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
                      const PhosphorIcon(Icones.exportar, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exportar relatórios',
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
                          icon: const PhosphorIcon(Icones.pdf),
                          label: const Text('Exportar PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _exportarCSV(context, dados),
                          icon: const PhosphorIcon(Icones.planilha),
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
      const SnackBar(content: Text('Gerando relatório em PDF…')),
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
