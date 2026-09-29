import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_calculos_service.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';

import 'rebalanceamento_dialog.dart';

/// Patrimônio: só leitura. Os ativos e valores vêm do Open Finance e são
/// atualizados pela sincronização da Pluggy.
class InvestimentosScreen extends ConsumerWidget {
  const InvestimentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porClasse = ref.watch(investimentosPorClasseProvider);
    final patrimonio = ref.watch(patrimonioTotalProvider);
    final rendimento = ref.watch(rendimentoAcumuladoProvider);
    final custoTotal = ref.watch(custoTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            tooltip: 'Calculadora de Rebalanceamento',
            icon: const Icon(Icons.balance),
            onPressed: () => mostrarDialogoRebalanceamento(context),
          ),
          IconButton(
            tooltip: 'Calendário de Proventos',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push(AppRoutes.calendarioProventos),
          ),
        ],
      ),
      body: porClasse.totalAtivos == 0
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PatrimonioCard(
                  patrimonioCents: patrimonio,
                  rendimentoCents: rendimento,
                  custoCents: custoTotal,
                ),
                const SizedBox(height: 16),
                for (final grupo in porClasse.grupos) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      grupo.classe.rotulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  for (final investimento in grupo.investimentos)
                    _InvestimentoTile(
                      investimento: investimento,
                      onTap: () => context.push(
                        AppRoutes.investimentoDetalheDe(investimento.id),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum investimento encontrado',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Seus investimentos aparecem aqui automaticamente, vindos '
                  'dos bancos conectados no Open Finance.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PatrimonioCard extends StatelessWidget {
  const _PatrimonioCard({
    required this.patrimonioCents,
    required this.rendimentoCents,
    required this.custoCents,
  });

  final int patrimonioCents;
  final int rendimentoCents;
  final int custoCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positivo = rendimentoCents >= 0;
    final corRendimento =
        positivo ? Colors.green.shade700 : theme.colorScheme.error;
    final pct = custoCents > 0
        ? (rendimentoCents / custoCents * 100).abs().round()
        : 0;
    final textoPct = custoCents > 0
        ? '${positivo ? '+' : '-'}$pct%'
        : '—';

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimônio total',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatoBRL(patrimonioCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            // Sem custo registrado não há como calcular o rendimento.
            if (custoCents > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  positivo ? Icons.trending_up : Icons.trending_down,
                  color: corRendimento,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${positivo ? '+' : '-'}'
                  '${formatoBRL(rendimentoCents.abs())} '
                  '($textoPct)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: corRendimento,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvestimentoTile extends ConsumerWidget {
  const _InvestimentoTile({
    required this.investimento,
    required this.onTap,
  });

  final Investimento investimento;
  final VoidCallback onTap;

  String _subtitle(PrecoMedioResultado? pm) {
    final sb = StringBuffer();
    if (investimento.ePorQuantidade) {
      final qtd = investimento.quantidade.toStringAsFixed(
        investimento.quantidade == investimento.quantidade.roundToDouble()
            ? 0
            : 2,
      );
      sb.write('$qtd un · ${formatoBRL(investimento.precoAtualCents)}');
      if (pm != null && pm.precoMedioCents > 0) {
        sb.write(' · PM: ${formatoBRL(pm.precoMedioCents)}');
      }
    } else {
      sb.write(investimento.classe.rotulo);
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pm = ref.watch(precoMedioPorAtivoProvider(investimento.id));
    final isLucro = (pm?.lucroPrejuizoCents ?? 0) >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.trending_up,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(investimento.nome),
        subtitle: Text(
          investimento.importadoOpenFinance
              ? '${_subtitle(pm)} · Open Finance'
              : _subtitle(pm),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatoBRL(investimento.patrimonioCents),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (pm != null && pm.custoTotalCents > 0)
              Text(
                '${isLucro ? "+" : ""}${pm.rentabilidadePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      isLucro ? Colors.green.shade700 : theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

