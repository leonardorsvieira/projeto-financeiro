import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/lancamentos_providers.dart';
import '../domain/lancamento.dart';
import '../domain/lancamento_converter.dart';

class ProximosVencimentosScreen extends ConsumerWidget {
  const ProximosVencimentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vencimentos = ref.watch(proximosVencimentosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Próximos vencimentos')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(lancamentosRepositoryProvider).ensureVigenteCopies();
          ref.invalidate(proximosVencimentosProvider);
        },
        child: vencimentos.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vencimentos.length,
                itemBuilder: (context, index) {
                  final item = vencimentos[index];
                  return _VencimentoTile(item: item);
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
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
                  Icons.event_available_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum vencimento próximo',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lançamentos com data de vencimento futura aparecerão aqui.',
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

class _VencimentoTile extends StatelessWidget {
  const _VencimentoTile({required this.item});

  final Lancamento item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valor = formatoBRL(item.valorCents);
    final dataVenc = formatoData(item.vencimento!);
    final isFixa = item.fixoMensal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {}, // TODO: navegar para edição se necessário
        leading: CircleAvatar(
          child: Text(
            item.categoria.characters.first,
            style: theme.textTheme.bodySmall,
          ),
        ),
        title: Text(item.descricao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.categoria} · ${item.formaPagamento}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                _Badge(
                  label: 'Vence $dataVenc',
                  icon: Icons.schedule_outlined,
                  color: theme.colorScheme.tertiary,
                ),
                if (isFixa)
                  _Badge(
                    label: 'Fixa mensal',
                    icon: Icons.repeat_outlined,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(
          valor,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}