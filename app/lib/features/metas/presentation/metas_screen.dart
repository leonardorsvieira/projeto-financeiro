import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/metas_providers.dart';
import '../domain/meta.dart';

class MetasScreen extends ConsumerStatefulWidget {
  const MetasScreen({super.key});

  @override
  ConsumerState<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends ConsumerState<MetasScreen> {
  Future<void> _salvarMeta({
    Meta? meta,
    String? categoria,
    required int valorLimiteCents,
  }) async {
    final repo = ref.read(metasRepositoryProvider);
    if (meta == null) {
      await repo.create(
        categoria: categoria!,
        valorLimiteCents: valorLimiteCents,
      );
    } else {
      await repo.update(
        meta,
        categoria: categoria ?? meta.categoria,
        valorLimiteCents: valorLimiteCents,
      );
    }
  }

  Future<void> _excluir(String id) async {
    await ref.read(metasRepositoryProvider).delete(id);
  }

  Future<void> _abrirDialog({Meta? meta}) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MetaDialog(meta: meta),
    );
    if (resultado == null || !mounted) return;
    try {
      await _salvarMeta(
        meta: meta,
        categoria: resultado['categoria'] as String?,
        valorLimiteCents: resultado['valorLimiteCents'] as int,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar a meta.')),
      );
    }
  }

  Future<void> _excluirComConfirmacao(Meta meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta?'),
        content: Text(
          'A meta de ${meta.categoria} será removida. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await _excluir(meta.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir a meta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metas = ref.watch(metasComProgressoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nova meta'),
      ),
      body: metas.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: metas.length,
              itemBuilder: (context, index) {
                final item = metas[index];
                return _MetaTile(
                  item: item,
                  onEditar: () => _abrirDialog(meta: item.meta),
                  onExcluir: () => _excluirComConfirmacao(item.meta),
                );
              },
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
                  Icons.track_changes_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma meta criada',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina um limite mensal de gasto por categoria para acompanhar o progresso.',
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.item,
    required this.onEditar,
    required this.onExcluir,
  });

  final MetaComProgresso item;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  Color _corProgresso(ColorScheme scheme) {
    if (item.estourou) return scheme.error;
    if (item.quaseEstourada) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = _corProgresso(theme.colorScheme);
    final pct = item.percentual;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.meta.categoria,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ações',
                  onSelected: (value) {
                    if (value == 'editar') onEditar();
                    if (value == 'excluir') onExcluir();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatoBRL(item.gastoCents)} de ${formatoBRL(item.meta.valorLimiteCents)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 100) / 100,
                minHeight: 8,
                color: cor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final sufixo = [
                if (item.estourou) 'limite estourado',
                if (item.quaseEstourada) 'quase no limite',
              ].join(' · ');
              return Text(
                sufixo.isEmpty ? '$pct%' : '$pct% · $sufixo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MetaDialog extends StatefulWidget {
  const _MetaDialog({this.meta});

  final Meta? meta;

  @override
  State<_MetaDialog> createState() => _MetaDialogState();
}

class _MetaDialogState extends State<_MetaDialog> {
  late final TextEditingController _valorController;
  String? _categoria;
  bool _isSaving = false;

  bool get _editando => widget.meta != null;

  @override
  void initState() {
    super.initState();
    _categoria = widget.meta?.categoria;
    _valorController = TextEditingController(
      text: widget.meta == null
          ? ''
          : formatoBRL(widget.meta!.valorLimiteCents).replaceAll(
              'R\$', '',
            ).trim(),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final valor = parseValorBRLParaCentavos(_valorController.text);
    if (_categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma categoria.')),
      );
      return;
    }
    if (valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context, {
      'categoria': _categoria,
      'valorLimiteCents': valor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar meta' : 'Nova meta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [
              for (final c in categorias)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _categoria = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limite mensal',
              prefixText: 'R\$ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}