import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/rendimento_investimento.dart';

const _meses = [
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
  'Dezembro',
];

/// Rendimentos agregados por mês (total do mês + detalhe por ativo).
class RendimentosScreen extends ConsumerWidget {
  const RendimentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meses = ref.watch(rendimentosPorMesProvider);
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];

    String nomeAtivo(String id) {
      for (final i in investimentos) {
        if (i.id == id) return i.nome;
      }
      return 'Investimento';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rendimentos')),
      body: meses.isEmpty
          ? ListView(
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
                          Icons.card_giftcard,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum rendimento recebido',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dividendos, juros e outros rendimentos aparecem aqui, somados por mês.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final mes in meses) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_meses[mes.mes - 1]} ${mes.ano}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatoBRL(mes.totalCents),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final r in mes.rendimentos)
                    _RendimentoMesTile(
                      rendimento: r,
                      nomeAtivo: nomeAtivo(r.investimentoId),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _RendimentoMesTile extends StatelessWidget {
  const _RendimentoMesTile({
    required this.rendimento,
    required this.nomeAtivo,
  });

  final RendimentoInvestimento rendimento;
  final String nomeAtivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.green,
          ),
        ),
        title: Text(nomeAtivo),
        subtitle: Text(
          '${rendimento.tipo.rotulo} · ${formatoData(rendimento.data)}',
        ),
        trailing: Text(
          '+${formatoBRL(rendimento.valorCents)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}