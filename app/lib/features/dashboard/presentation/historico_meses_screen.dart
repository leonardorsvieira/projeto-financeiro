import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/dashboard_providers.dart';

/// Tela dedicada ao Histórico de Gastos dos Meses Anteriores (`/historico-meses`).
/// Exibe cartões mensais com Entradas, Saídas e Saldo dos últimos 6 a 12 meses.
class HistoricoMesesScreen extends ConsumerWidget {
  const HistoricoMesesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historico = ref.watch(historicoUltimosMesesProvider);
    final mesSelecionado = ref.watch(mesSelecionadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Meses'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history_outlined, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução dos Últimos Meses',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toque em qualquer mês para analisar o extrato detalhado e gastos por categoria.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final item in historico) ...[
            _CardMesHistorico(
              mesAno: item.mesAno,
              resumo: item.resumo,
              isSelecionado: item.mesAno.year == mesSelecionado.year &&
                  item.mesAno.month == mesSelecionado.month,
              onTap: () {
                ref
                    .read(mesSelecionadoProvider.notifier)
                    .selecionarMes(item.mesAno);
                context.pop();
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CardMesHistorico extends StatelessWidget {
  const _CardMesHistorico({
    required this.mesAno,
    required this.resumo,
    required this.isSelecionado,
    required this.onTap,
  });

  static const _meses = [
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

  final DateTime mesAno;
  final ResumoMes resumo;
  final bool isSelecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nomeCapitalizado = '${_meses[mesAno.month - 1]} ${mesAno.year}';
    final saldoPositivo = resumo.saldoCents >= 0;

    return Card(
      elevation: isSelecionado ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelecionado
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nomeCapitalizado,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelecionado ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (isSelecionado)
                    Chip(
                      label: const Text('Mês Atual'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColuna(
                    rotulo: 'Entradas',
                    valor: formatoBRL(resumo.entradasCents),
                    cor: Colors.green.shade700,
                  ),
                  _InfoColuna(
                    rotulo: 'Saídas',
                    valor: formatoBRL(resumo.saidasCents),
                    cor: theme.colorScheme.error,
                  ),
                  _InfoColuna(
                    rotulo: 'Saldo',
                    valor: formatoBRL(resumo.saldoCents),
                    cor: saldoPositivo
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoColuna extends StatelessWidget {
  const _InfoColuna({
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
        Text(rotulo, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          valor,
          style: theme.textTheme.titleSmall?.copyWith(
            color: cor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
