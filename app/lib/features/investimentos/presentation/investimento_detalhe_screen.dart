import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';
import 'investimentos_screen.dart' show corRendimento, textoRendimento;

/// Detalhe de um ativo (só leitura): a posição vem do Open Finance e é
/// atualizada pela sincronização da Pluggy.
class InvestimentoDetalheScreen extends ConsumerWidget {
  const InvestimentoDetalheScreen({super.key, required this.investimentoId});

  final String investimentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
    Investimento? investimento;
    for (final i in investimentos) {
      if (i.id == investimentoId) investimento = i;
    }

    return Scaffold(
      appBar: AppBar(title: Text(investimento?.nome ?? 'Investimento')),
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

class _ResumoInvestimento extends StatelessWidget {
  const _ResumoInvestimento({required this.investimento});

  final Investimento investimento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rendimento = investimento.rendimentoCents;
    final investido = investimento.valorInvestidoCents;

    Widget coluna(String rotulo, String valor, {Color? cor}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: theme.textTheme.labelSmall),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investimento.classe.rotulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Patrimônio: ${formatoBRL(investimento.patrimonioCents)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (investimento.ePorQuantidade) ...[
              const SizedBox(height: 4),
              Text(
                '${investimento.quantidade.toStringAsFixed(2)} un · '
                '${formatoBRL(investimento.precoAtualCents)}/un',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const Divider(height: 24),
            if (investido == null || rendimento == null)
              Text(
                'O banco não informou o valor aplicado neste investimento, '
                'então não dá para calcular o rendimento.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  coluna('Aplicado', formatoBRL(investido)),
                  coluna(
                    'Valor atual',
                    formatoBRL(investimento.patrimonioCents),
                  ),
                  coluna(
                    rendimento >= 0 ? 'Rendeu' : 'Perdeu',
                    textoRendimento(
                      rendimento,
                      investimento.rentabilidadePercent,
                    ),
                    cor: corRendimento(context, rendimento),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
