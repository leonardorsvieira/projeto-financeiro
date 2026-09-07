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
  final _diaVencimentoController = TextEditingController();
  String _categoria = 'Outros';
  String _formaPagamento = 'Pix';
  TipoLancamento _tipo = TipoLancamento.despesa;
  DateTime _data = DateTime.now();
  DateTime? _vencimento;
  bool _isSaving = false;
  bool _loaded = false;
  bool _fixoMensal = false;
  final List<_ItemForm> _itens = [];

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _obsController.dispose();
    _diaVencimentoController.dispose();
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
    _tipo = lancamento.tipo;
    _data = lancamento.data;
    _vencimento = lancamento.vencimento;
    _fixoMensal = lancamento.fixoMensal;
    if (lancamento.serieId != null) {
      // manter serieId se editando (não re-gerar)
    }
    if (lancamento.itens != null) {
      _itens.addAll(lancamento.itens!.map((i) => _ItemForm(
        descricao: i.descricao,
        valorCents: i.valorCents,
      )));
    }
    if (_fixoMensal && _vencimento != null) {
      _diaVencimentoController.text = _vencimento!.day.toString();
    }
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

  void _addItem() {
    setState(() => _itens.add(_ItemForm()));
  }

  void _removeItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  int get _somaItens => _itens.fold(0, (s, i) => s + (i.valorCents ?? 0));

  bool get _temItensValidos => _itens.any((i) => i.descricao.isNotEmpty || i.valorCents != null);

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação de itens
    if (_temItensValidos) {
      for (int i = 0; i < _itens.length; i++) {
        final item = _itens[i];
        if (item.descricao.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item ${i + 1}: descrição obrigatória')),
          );
          return;
        }
        if (item.valorCents == null || item.valorCents! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item ${i + 1}: valor obrigatório')),
          );
          return;
        }
      }
    }

    int valorFinal;
    if (_temItensValidos) {
      valorFinal = _somaItens;
    } else {
      final parsed = parseValorBRLParaCentavos(_valorController.text);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor inválido')),
        );
        return;
      }
      valorFinal = parsed;
    }

    final descricao = _descricaoController.text.trim();
    final obs = _obsController.text.trim().isEmpty
        ? null
        : _obsController.text.trim();

    DateTime? vencimentoFinal = _vencimento;
    if (_fixoMensal) {
      final dia = int.tryParse(_diaVencimentoController.text);
      if (dia == null || dia < 1 || dia > 31) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dia do vencimento inválido (1-31)')),
        );
        return;
      }
      final agora = DateTime.now();
      int mes = agora.month;
      int ano = agora.year;
      if (_data.isAfter(DateTime(ano, mes, dia))) {
        mes++;
        if (mes > 12) {
          mes = 1;
          ano++;
        }
      }
      int diaFinal = dia;
      final ultimoDia = DateTime(ano, mes + 1, 0).day;
      if (diaFinal > ultimoDia) diaFinal = ultimoDia;
      vencimentoFinal = DateTime(ano, mes, diaFinal);
    }

    final itensParaSalvar = _temItensValidos
        ? _itens
            .where((i) => i.descricao.trim().isNotEmpty && i.valorCents != null)
            .map((i) => LancamentoItem(
                  descricao: i.descricao.trim(),
                  valorCents: i.valorCents!,
                ))
            .toList()
        : null;

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
          valorCents: valorFinal,
          categoria: _categoria,
          formaPagamento: _formaPagamento,
          tipo: _tipo,
          data: _data,
          vencimento: _tipo == TipoLancamento.despesa ? vencimentoFinal : null,
          obs: obs,
          itens: itensParaSalvar,
          fixoMensal: _fixoMensal,
          serieId: atual.serieId,
        );
      } else {
        await repo.create(
          descricao: descricao,
          valorCents: valorFinal,
          categoria: _categoria,
          formaPagamento: _formaPagamento,
          tipo: _tipo,
          data: _data,
          vencimento: _tipo == TipoLancamento.despesa ? vencimentoFinal : null,
          obs: obs,
          itens: itensParaSalvar,
          fixoMensal: _fixoMensal,
          serieId: _fixoMensal ? null : null, // será definido no create se fixo
        );
        // Se era fixa, o create já gerou a cópia e definiu serieId
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
                    SegmentedButton<TipoLancamento>(
                      segments: const [
                        ButtonSegment(
                          value: TipoLancamento.despesa,
                          icon: Icon(Icons.trending_down),
                          label: Text('Despesa'),
                        ),
                        ButtonSegment(
                          value: TipoLancamento.receita,
                          icon: Icon(Icons.trending_up),
                          label: Text('Receita'),
                        ),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: _isSaving
                          ? null
                          : (s) => setState(() => _tipo = s.first),
                    ),
                    const SizedBox(height: 16),
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
                    if (!_temItensValidos) ...[
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
                    ],
                    // Seção de Itens
                    if (_temItensValidos || _itens.isNotEmpty) ...[
                      const Text(
                        'Itens',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ..._itens.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.descricao,
                                        textCapitalization: TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                          labelText: 'Descrição do item',
                                          prefixIcon: Icon(Icons.shopping_basket_outlined),
                                        ),
                                        onChanged: (v) => item.descricao = v,
                                        validator: (v) => v?.trim().isEmpty ?? true
                                            ? 'Obrigatório'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.valorCents != null
                                            ? (item.valorCents! / 100).toStringAsFixed(2).replaceAll('.', ',')
                                            : '',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Valor (R\$)',
                                          prefixIcon: Icon(Icons.attach_money),
                                        ),
                                        onChanged: (v) {
                                          final parsed = parseValorBRLParaCentavos(v);
                                          item.valorCents = parsed;
                                          setState(() {}); // atualiza soma
                                        },
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return null; // opcional se tem outros itens
                                          final p = parseValorBRLParaCentavos(v);
                                          return p == null || p <= 0 ? 'Inválido' : null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _removeItem(idx),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_itens.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ${formatoBRL(_somaItens)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar item'),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                    if (_tipo == TipoLancamento.despesa) ...[
                      // Checkbox "Despesa fixa mensal"
                      CheckboxListTile(
                        value: _fixoMensal,
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _fixoMensal = v ?? false),
                        title: const Text('Despesa fixa mensal'),
                        subtitle: const Text('Gera cópias automáticas nos próximos meses'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_fixoMensal) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _diaVencimentoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dia do vencimento (1-31)',
                            prefixIcon: Icon(Icons.schedule_outlined),
                          ),
                          validator: (v) {
                            if (!_fixoMensal) return null;
                            final d = int.tryParse(v ?? '');
                            return (d == null || d < 1 || d > 31) ? '1-31' : null;
                          },
                        ),
                      ] else ...[
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
                      ],
                    ] else ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickData,
                        icon: const Icon(Icons.event_outlined),
                        label: Text('Data: ${formatoData(_data)}'),
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

class _ItemForm {
  _ItemForm({this.descricao = '', this.valorCents});
  String descricao;
  int? valorCents;
}