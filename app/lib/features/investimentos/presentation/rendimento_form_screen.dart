import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/rendimento_investimento.dart';

/// Formulário de rendimento (novo/edição) de um investimento.
class RendimentoFormScreen extends ConsumerStatefulWidget {
  const RendimentoFormScreen({
    super.key,
    required this.investimentoId,
    this.rendimento,
  });

  final String investimentoId;
  final RendimentoInvestimento? rendimento;

  bool get isEdit => rendimento != null;

  @override
  ConsumerState<RendimentoFormScreen> createState() =>
      _RendimentoFormScreenState();
}

class _RendimentoFormScreenState extends ConsumerState<RendimentoFormScreen> {
  final _valorController = TextEditingController();
  late TipoRendimentoInvestimento _tipo;
  late DateTime _data;
  bool _isSaving = false;

  bool get _editando => widget.rendimento != null;

  @override
  void initState() {
    super.initState();
    final rendimento = widget.rendimento;
    _tipo = rendimento?.tipo ?? TipoRendimentoInvestimento.dividendo;
    _data = rendimento?.data ?? DateTime.now();
    _valorController.text = rendimento != null
        ? (rendimento.valorCents / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '';
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _salvar() async {
    final valorCents = parseValorBRLParaCentavos(_valorController.text);
    if (valorCents == null || valorCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }
    if (!widget.isEdit && widget.investimentoId.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(rendimentosInvestimentoRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(
          widget.rendimento!.copyWith(
            tipo: _tipo,
            valorCents: valorCents,
            data: _data,
          ),
        );
      } else {
        await repo.create(
          RendimentoInvestimento(
            id: '',
            investimentoId: widget.investimentoId,
            tipo: _tipo,
            valorCents: valorCents,
            data: _data,
          ),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar o rendimento.')),
      );
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir rendimento?'),
        content: const Text(
          'O rendimento será removido. Essa ação não pode ser desfeita.',
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
      await ref
          .read(rendimentosInvestimentoRepositoryProvider)
          .delete(widget.rendimento!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir o rendimento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
    var nome = '';
    for (final i in investimentos) {
      if (i.id == widget.investimentoId) nome = i.nome;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar rendimento' : 'Novo rendimento'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : _excluir,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            nome.isEmpty ? 'Investimento' : nome,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoRendimentoInvestimento>(
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final t in TipoRendimentoInvestimento.values)
                DropdownMenuItem(value: t, child: Text(t.rotulo)),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? _tipo),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor recebido',
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data'),
            subtitle: Text(formatoData(_data)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickData,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _salvar,
            icon: const Icon(Icons.check),
            label: Text(_editando ? 'Salvar' : 'Registrar'),
          ),
        ],
      ),
    );
  }
}