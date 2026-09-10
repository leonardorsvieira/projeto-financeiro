import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../application/lancamentos_providers.dart';
import '../domain/lancamento.dart';
import '../domain/lancamento_converter.dart';

import '../application/exportar_service.dart';

/// Corpo da aba "Lançamentos" do home. Sem Scaffold próprio — a HomeScreen
/// (dashboard) é quem fornece AppBar, ações e FABs.
class LancamentosListScreen extends ConsumerWidget {
  const LancamentosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garantir cópias vigentes ao carregar a lista
    ref.listenManual(lancamentosStreamProvider, (_, _) async {
      await ref.read(lancamentosRepositoryProvider).ensureVigenteCopies();
    });

    final lancamentos = ref.watch(lancamentosStreamProvider);

    return lancamentos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        onRetry: () => ref.invalidate(lancamentosStreamProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState();
        }
        return _ListaComFiltro(items: items);
      },
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

class _ListaComFiltro extends ConsumerStatefulWidget {
  const _ListaComFiltro({required this.items});

  final List<Lancamento> items;

  @override
  ConsumerState<_ListaComFiltro> createState() => _ListaComFiltroState();
}

class _ListaComFiltroState extends ConsumerState<_ListaComFiltro> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtroTipo = 'todos'; // 'todos', 'despesa', 'receita'

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _exportarCSV(List<Lancamento> filtrados) {
    final csvContent = ExportarService.gerarCSV(filtrados);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${filtrados.length} lançamentos formatados para Excel:'),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csvContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final termoBusca = _buscaController.text.trim().toLowerCase();

    final filtrados = widget.items.where((item) {
      final tipoMatch = _filtroTipo == 'todos' ||
          (_filtroTipo == 'receita' && item.tipo == TipoLancamento.receita) ||
          (_filtroTipo == 'despesa' && item.tipo != TipoLancamento.receita);

      final buscaMatch = termoBusca.isEmpty ||
          item.descricao.toLowerCase().contains(termoBusca) ||
          item.categoria.toLowerCase().contains(termoBusca);

      return tipoMatch && buscaMatch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: _buscaController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar lançamento por nome ou categoria...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _buscaController.clear()),
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroTipo == 'todos',
                    onSelected: (_) => setState(() => _filtroTipo = 'todos'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Despesas'),
                    selected: _filtroTipo == 'despesa',
                    onSelected: (_) => setState(() => _filtroTipo = 'despesa'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Receitas'),
                    selected: _filtroTipo == 'receita',
                    onSelected: (_) => setState(() => _filtroTipo = 'receita'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Exportar para CSV (Excel)',
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () => _exportarCSV(filtrados),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtrados.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum lançamento encontrado.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
          final ehReceita = item.tipo == TipoLancamento.receita;
          final valor = '${ehReceita ? '+' : '-'}${formatoBRL(item.valorCents)}';
          final corValor = ehReceita
              ? Colors.green.shade700
              : theme.colorScheme.error;
          final hasVencimento = item.vencimento != null;
          final isFixa = item.fixoMensal;
          
          return ListTile(
            onTap: () => context.push(AppRoutes.lancamentoEditar(item.id)),
            leading: CircleAvatar(
              backgroundColor: ehReceita
                  ? Colors.green.withValues(alpha: 0.15)
                  : null,
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
                if (hasVencimento || isFixa || ehReceita) ...[
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
                      if (ehReceita)
                        _Badge(
                          label: 'Receita',
                          icon: Icons.arrow_downward,
                          color: Colors.green.shade700,
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
                    color: corValor,
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
    ),
  ],
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