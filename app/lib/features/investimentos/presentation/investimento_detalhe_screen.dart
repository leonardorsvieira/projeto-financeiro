import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';

/// Detalhe de um ativo (só leitura): a posição vem do Open Finance e é
/// atualizada pela sincronização da Pluggy.
class InvestimentoDetalheScreen extends ConsumerWidget {
  const InvestimentoDetalheScreen({
    super.key,
    required this.investimentoId,
  });

  final String investimentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
    Investimento? investimento;
    for (final i in investimentos) {
      if (i.id == investimentoId) investimento = i;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(investimento?.nome ?? 'Investimento'),
      ),
      body: investimento == null
          ? const Center(child: Text('Ativo não encontrado.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumoInvestimento(investimento: investimento),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Valores atualizados automaticamente pelo Open Finance.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ResumoInvestimento extends ConsumerWidget {
  const _ResumoInvestimento({required this.investimento});

  final Investimento investimento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pmResultado =
        ref.watch(precoMedioPorAtivoProvider(investimento.id));

    final detalhe = investimento.ePorQuantidade
        ? '${investimento.quantidade.toStringAsFixed(2)} un · '
            '${formatoBRL(investimento.precoAtualCents)}/un'
        : investimento.classe.rotulo;

    final isLucro = (pmResultado?.lucroPrejuizoCents ?? 0) >= 0;
    final corLucro = isLucro ? Colors.green.shade700 : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  investimento.classe.rotulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pmResultado != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLucro
                          ? Colors.green.shade100
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${isLucro ? "+" : ""}${pmResultado.rentabilidadePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLucro
                            ? Colors.green.shade800
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Patrimônio: ${formatoBRL(investimento.patrimonioCents)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(detalhe, style: theme.textTheme.bodyMedium),
            if (pmResultado != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preço Médio (PM)',
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        investimento.ePorQuantidade
                            ? '${formatoBRL(pmResultado.precoMedioCents)}/un'
                            : formatoBRL(pmResultado.custoTotalCents),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Custo Total Aportado',
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        formatoBRL(pmResultado.custoTotalCents),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ganho / Perda', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${isLucro ? "+" : ""}${formatoBRL(pmResultado.lucroPrejuizoCents)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: corLucro,
                        ),
                      ),
                    ],
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
