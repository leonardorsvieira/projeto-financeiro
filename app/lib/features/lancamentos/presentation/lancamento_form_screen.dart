import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/lancamentos_providers.dart';
import '../domain/lancamento.dart';
import '../domain/lancamento_converter.dart';
import 'lancamento_form_validators.dart';

class LancamentoFormScreen extends ConsumerStatefulWidget {
  const LancamentoFormScreen({super.key, this.lancamentoId});

  final String? lancamentoId;

  bool get isEdit => lancamentoId != null;

  @override
  ConsumerState<LancamentoFormScreen> createState() =>
      _LancamentoFormScreenState();
}

class _LancamentoFormScreenState extends ConsumerState<LancamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _obsController = TextEditingController();
  String _categoria = 'Outros';
  String _formaPagamento = 'Pix';
  DateTime _data = DateTime.now();
  DateTime? _vencimento;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _prefill(Lancamento lancamento) {
    if (_loaded) return;
    _loaded = true;
    _descricaoController.text = lancamento.descricao;
    _valorController.text = (lancamento.valorCents / 100)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _categoria = lancamento.categoria;
    _formaPagamento = lancamento.formaPagamento;
    _data = lancamento.data;
    _vencimento = lancamento.vencimento;
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

  Future<void> _pickVencimento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vencimento ?? _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _vencimento = picked);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final lucro = parseValorBRLParaCentavos(_valorController.text)!;
    final descricao = _descricaoController.text.trim();
    final obs = _obsController.text.trim().isEmpty
        ? null
        : _obsController.text.trim();

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(lancamentosRepositoryProvider);
      if (widget.isEdit) {
        final atual = await ref.read(
          lancamentoByIdProvider(widget.lancamentoId!).future,
        );
        if (atual == null) throw Exception('não encontrado');
        await repo.update(
          atual,
          descricao: descricao,
          valorCents: lucro,
          categoria: _categoria,
          formaPagamento: _formaPagamento,
          data: _data,
          vencimento: _vencimento,
          obs: obs,
        );
      } else {
        await repo.create(
          descricao: descricao,
          valorCents: lucro,
          categoria: _categoria,
          formaPagamento: _formaPagamento,
          data: _data,
          vencimento: _vencimento,
          obs: obs,
        );
      }
      if (mounted) context.pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar.')),
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final loaded = ref.watch(lancamentoByIdProvider(widget.lancamentoId!));
      final data = loaded.value;
      if (data != null) _prefill(data);
    }

    final title = widget.isEdit ? 'Editar lançamento' : 'Novo lançamento';

    if (widget.isEdit && !_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: validateDescricao,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: validateValor,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final c in categorias)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) =>
                              setState(() => _categoria = value ?? 'Outros'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _formaPagamento,
                      decoration: const InputDecoration(
                        labelText: 'Forma de pagamento',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items: [
                        for (final f in formasPagamento)
                          DropdownMenuItem(value: f, child: Text(f)),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(
                              () => _formaPagamento = value ?? 'Pix'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickData,
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Data: ${formatoData(_data)}'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickVencimento,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        _vencimento == null
                            ? 'Vencimento (opcional)'
                            : 'Vencimento: ${formatoData(_vencimento!)}',
                      ),
                    ),
                    if (_vencimento != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _vencimento = null),
                          child: const Text('Remover vencimento'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _obsController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        alignLabelWithHint: true,
                      ),
                      validator: validateObs,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => context.pop(false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _salvar,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isSaving ? 'Salvando...' : 'Salvar',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}