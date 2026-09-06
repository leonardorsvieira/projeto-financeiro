import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../application/lancamentos_providers.dart';
import '../domain/lancamento.dart';
import '../domain/lancamento_converter.dart';

class LancamentosListScreen extends ConsumerWidget {
  const LancamentosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lancamentos = ref.watch(lancamentosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Bolso'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ditar',
            onPressed: () => context.push(AppRoutes.lancamentoDitado),
            icon: const Icon(Icons.mic),
            label: const Text('Ditar'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'novo',
            tooltip: 'Novo lançamento',
            onPressed: () => context.push(AppRoutes.lancamentoNovo),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: lancamentos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(lancamentosStreamProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return _Lista(items: items);
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text('Não foi possível carregar os lançamentos.'),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum lançamento ainda',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque em + para registrar sua primeira despesa.',
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

class _Lista extends ConsumerWidget {
  const _Lista({required this.items});

  final List<Lancamento> items;

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Lancamento lancamento,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text(
          'Você está prestes a excluir "${lancamento.descricao}". '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lancamentosRepositoryProvider).delete(lancamento.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Lançamento excluído.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final valor = formatoBRL(item.valorCents);
          return ListTile(
            onTap: () => context.push(AppRoutes.lancamentoEditar(item.id)),
            leading: CircleAvatar(
              child: Text(
                item.categoria.characters.first,
                style: theme.textTheme.bodySmall,
              ),
            ),
            title: Text(item.descricao),
            subtitle: Text(
              '${formatoData(item.data)} · ${item.categoria}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ações',
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmarExclusao(context, ref, item);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Excluir'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}