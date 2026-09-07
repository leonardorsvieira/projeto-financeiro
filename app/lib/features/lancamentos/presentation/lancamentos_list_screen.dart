import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../application/lancamentos_providers.dart';
import '../application/lembretes_controller.dart';
import '../application/preferencias_service.dart';
import '../domain/lancamento.dart';
import '../domain/lancamento_converter.dart';

class LancamentosListScreen extends ConsumerWidget {
  const LancamentosListScreen({super.key});

  Future<void> _abrirHorarioLembretes(BuildContext context, WidgetRef ref) async {
    final prefs = await ref.read(preferenciasLembretesProvider.future);
    if (!context.mounted) return;

    // Escolher horário (padrão 09:00 configurável).
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.hora, minute: prefs.minuto),
      helpText: 'Horário dos lembretes',
    );
    if (horario == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final novo = PreferenciasLembretes(
        hora: horario.hour,
        minuto: horario.minute,
      );
      await ref.read(lembretesControllerProvider.notifier).alterarHorario(novo);
      messenger.showSnackBar(
        SnackBar(content: Text('Lembretes ajustados para ${novo.label}.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível ajustar os lembretes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garantir cópias vigentes ao carregar a lista
    ref.listenManual(lancamentosStreamProvider, (_, _) async {
      await ref.read(lancamentosRepositoryProvider).ensureVigenteCopies();
    });

    final lancamentos = ref.watch(lancamentosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Bolso'),
        actions: [
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS))
            IconButton(
              tooltip: 'Horário dos lembretes',
              onPressed: () => _abrirHorarioLembretes(context, ref),
              icon: const Icon(Icons.notifications_outlined),
            ),
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
    final isFixa = lancamento.fixoMensal && lancamento.serieId != null;
    
    final acao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFixa ? 'Excluir lançamento fixo?' : 'Excluir lançamento?'),
        content: Text(
          isFixa
              ? 'Este lançamento faz parte de uma série fixa mensal.\n'
                  'O que deseja fazer?'
              : 'Você está prestes a excluir "${lancamento.descricao}". '
                  'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          if (isFixa) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete_one'),
              child: const Text('Apenas este mês'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('delete_series'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir série toda'),
            ),
          ] else ...[
            FilledButton(
              onPressed: () => Navigator.of(context).pop('delete_one'),
              child: const Text('Excluir'),
            ),
          ],
        ],
      ),
    );

    if (acao == null || acao == 'cancel' || !context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (acao == 'delete_series') {
        await ref.read(lancamentosRepositoryProvider).excluirSerie(lancamento.serieId!);
        messenger.showSnackBar(
          const SnackBar(content: Text('Série toda excluída.')),
        );
      } else {
        await ref.read(lancamentosRepositoryProvider).delete(lancamento.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Lançamento excluído.')),
        );
      }
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
          final hasVencimento = item.vencimento != null;
          final isFixa = item.fixoMensal;
          
          return ListTile(
            onTap: () => context.push(AppRoutes.lancamentoEditar(item.id)),
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
                Text(
                  '${formatoData(item.data)} · ${item.categoria}',
                ),
                if (hasVencimento || isFixa) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      if (hasVencimento)
                        _Badge(
                          label: 'Vence ${formatoData(item.vencimento!)}',
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
              ],
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(
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