import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart'
    show LancamentoItem, TipoLancamento;
import '../../lancamentos/domain/lancamento_converter.dart'
    show parseValorBRLParaCentavos, formatoBRL, categorias, formasPagamento, formatoData;
import '../../lancamentos/presentation/lancamento_form_validators.dart'
    show validateDescricao, validateValor;
import '../application/ditado_providers.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';

class _ItemForm {
  _ItemForm({this.descricao = '', this.valorReais});
  String descricao;
  String? valorReais;

  int? get valorCents {
    if (valorReais == null) return null;
    final v = valorReais!.replaceAll(',', '.');
    final d = double.tryParse(v);
    if (d == null) return null;
    return (d * 100).round();
  }
}

class ConfirmacaoDitadoScreen extends ConsumerStatefulWidget {
  const ConfirmacaoDitadoScreen({super.key, required this.rascunho});

  final RascunhoLancamento rascunho;

  @override
  ConsumerState<ConfirmacaoDitadoScreen> createState() =>
      _ConfirmacaoDitadoScreenState();
}

class _ConfirmacaoDitadoScreenState
    extends ConsumerState<ConfirmacaoDitadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorFocus = FocusNode();
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  late String _categoria;
  late String _formaPagamento;
  late TipoLancamento _tipo;
  late DateTime _data;
  DateTime? _vencimento;
  bool _isSaving = false;
  CampoDitado? _gravandoCampo;
  CampoDitado? _processandoCampo;
  final List<_ItemForm> _itens = [];

  @override
  void initState() {
    super.initState();
    final rascunho = widget.rascunho;
    _descricaoController = TextEditingController(
      text: rascunho.descricao ?? '',
    );
    _valorController = TextEditingController(
      text: (rascunho.valorTexto ?? '').trim(),
    );
    _categoria = categorias.contains(rascunho.categoria)
        ? rascunho.categoria!
        : 'Outros';
    _formaPagamento = formasPagamento.contains(rascunho.formaPagamento)
        ? rascunho.formaPagamento!
        : 'Pix';
    _tipo =
        rascunho.tipo == 'receita' ? TipoLancamento.receita : TipoLancamento.despesa;
    _data = DateTime.tryParse(rascunho.dataIso ?? '') ?? DateTime.now();
    _vencimento = DateTime.tryParse(rascunho.vencimentoIso ?? '');
    if (rascunho.itens != null) {
      _itens.addAll(rascunho.itens!.map((i) => _ItemForm(
        descricao: i.descricao,
        valorReais: i.valorReais,
      )));
    }
    final valorVazio = (rascunho.valorTexto ?? '').trim().isEmpty;
    if (valorVazio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _valorFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  RascunhoLancamento _rascunhoAtual() => RascunhoLancamento(
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        valorTexto: _valorController.text.trim().isEmpty
            ? null
            : _valorController.text.trim(),
        categoria: _categoria,
        formaPagamento: _formaPagamento,
        tipo: _tipo.dbValue,
        dataIso: _data.toIso8601String().substring(0, 10),
        vencimentoIso:
            _vencimento?.toIso8601String().substring(0, 10),
        itens: _itens
            .where((i) => i.descricao.trim().isNotEmpty)
            .map((i) => RascunhoItem(
                  descricao: i.descricao.trim(),
                  valorReais: i.valorReais?.trim().isEmpty ?? true ? null : i.valorReais,
                ))
            .toList(),
      );

  void _aplicarCorrecao(CampoDitado campo, String? valor) {
    if (!mounted || valor == null) return;
    setState(() {
      switch (campo) {
        case CampoDitado.descricao:
          _descricaoController.text = valor;
        case CampoDitado.valor:
          _valorController.text = valor;
        case CampoDitado.categoria:
          if (categorias.contains(valor)) _categoria = valor;
        case CampoDitado.formaPagamento:
          if (formasPagamento.contains(valor)) _formaPagamento = valor;
        case CampoDitado.data:
          final data = DateTime.tryParse(valor);
          if (data != null) _data = data;
        case CampoDitado.vencimento:
          _vencimento = DateTime.tryParse(valor);
        case CampoDitado.itens:
          try {
            final List<dynamic> jsonList = json.decode(valor);
            _itens.clear();
            _itens.addAll(jsonList
                .whereType<Map<String, dynamic>>()
                .map((e) => _ItemForm(
                      descricao: e['descricao'] as String? ?? '',
                      valorReais: e['valor_reais'] as String?,
                    )));
          } catch (_) {
            // ignora erro de parse
          }
        case CampoDitado.tipo:
          if (valor == 'despesa' || valor == 'receita') {
            _tipo = valor == 'receita'
                ? TipoLancamento.receita
                : TipoLancamento.despesa;
          }
      }
    });
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _iniciarGravacaoCampo(CampoDitado campo) async {
    if (_isSaving ||
        _gravandoCampo != null ||
        _processandoCampo != null) {
      return;
    }
    final gravador = ref.read(audioRecorderServiceProvider);
    try {
      final permitido = await gravador.temPermissao();
      if (!permitido) {
        _mostrarMensagem('Permita o acesso ao microfone para ditar.');
        return;
      }
      await gravador.iniciar();
      if (mounted) setState(() => _gravandoCampo = campo);
    } on Object {
      _mostrarMensagem('Não consegui acessar o microfone.');
    }
  }

  Future<void> _pararGravacaoCampo() async {
    final campo = _gravandoCampo;
    if (campo == null) return;
    final gravador = ref.read(audioRecorderServiceProvider);
    final repositorio = ref.read(ditadoRepositoryProvider);
    setState(() {
      _gravandoCampo = null;
      _processandoCampo = campo;
    });
    try {
      final audio = await gravador.parar();
      if (audio == null || !mounted) return;
      final valor = await repositorio.corrigirCampo(
        campo,
        audio: audio,
        rascunhoAtual: _rascunhoAtual(),
      );
      _aplicarCorrecao(campo, valor);
    } on DitadoException catch (e) {
      _mostrarMensagem(e.mensagem);
    } on Object {
      _mostrarMensagem('Não consegui entender. Tente de novo.');
    } finally {
      if (mounted) setState(() => _processandoCampo = null);
    }
  }

  Widget _botaoVoz(CampoDitado campo) {
    if (_processandoCampo == campo) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_gravandoCampo == campo) {
      return IconButton.filled(
        onPressed: _pararGravacaoCampo,
        icon: const Icon(Icons.stop),
        color: Theme.of(context).colorScheme.error,
        tooltip: 'Parar',
      );
    }
    return IconButton(
      onPressed: () => _iniciarGravacaoCampo(campo),
      icon: const Icon(Icons.mic_none),
      tooltip: 'Corrigir por voz',
    );
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

    // Validar itens se houver
    if (_itens.isNotEmpty) {
      for (int i = 0; i < _itens.length; i++) {
        final item = _itens[i];
        if (item.descricao.trim().isEmpty) {
          _mostrarMensagem('Item ${i + 1}: descrição obrigatória');
          return;
        }
        if (item.valorReais == null || item.valorReais!.trim().isEmpty) {
          _mostrarMensagem('Item ${i + 1}: valor obrigatório');
          return;
        }
      }
    }

    int valorFinal;
    if (_itens.isNotEmpty) {
      valorFinal = _itens.fold<int>(0, (s, i) => s + (i.valorCents ?? 0));
    } else {
      final centavos = parseValorBRLParaCentavos(_valorController.text.trim());
      if (centavos == null) {
        _mostrarMensagem('Valor inválido');
        return;
      }
      valorFinal = centavos;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final itensParaSalvar = _itens.isNotEmpty
          ? _itens
              .where((i) =>
                  i.descricao.trim().isNotEmpty && i.valorReais != null)
              .map((i) => LancamentoItem(
                    descricao: i.descricao.trim(),
                    valorCents: i.valorCents!,
                  ))
              .toList()
          : null;

      await ref.read(lancamentosRepositoryProvider).create(
            descricao: _descricaoController.text.trim(),
            valorCents: valorFinal,
            categoria: _categoria,
            formaPagamento: _formaPagamento,
            tipo: _tipo,
            data: _data,
            vencimento: _tipo == TipoLancamento.despesa ? _vencimento : null,
            itens: itensParaSalvar,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar.')),
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar lançamento')),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SegmentedButton<TipoLancamento>(
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
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.tipo),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _descricaoController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            validator: validateDescricao,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.descricao),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _valorController,
                            focusNode: _valorFocus,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Valor (R\$)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            validator: validateValor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.valor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
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
                                : (value) => setState(
                                    () => _categoria = value ?? 'Outros'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.categoria),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
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
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.formaPagamento),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickData,
                            icon: const Icon(Icons.event_outlined),
                            label: Text('Data: ${formatoData(_data)}'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _botaoVoz(CampoDitado.data),
                      ],
                    ),
                    if (_tipo == TipoLancamento.despesa) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickVencimento,
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(
                                _vencimento == null
                                    ? 'Vencimento (opcional)'
                                    : 'Vencimento: ${formatoData(_vencimento!)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _botaoVoz(CampoDitado.vencimento),
                        ],
                      ),
                    ],
                    if (_gravandoCampo != null) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _pararGravacaoCampo,
                        style: FilledButton.styleFrom(
                          backgroundColor: tema.colorScheme.error,
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text('Toque para parar'),
                      ),
                    ],
                    // Seção de Itens (se houver)
                    if (_itens.isNotEmpty) ...[
                      const SizedBox(height: 24),
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.descricao,
                                    textCapitalization: TextCapitalization.sentences,
                                    decoration: const InputDecoration(
                                      labelText: 'Item',
                                      prefixIcon: Icon(Icons.shopping_basket_outlined),
                                    ),
                                    onChanged: (v) => item.descricao = v,
                                    validator: (v) =>
                                        v?.trim().isEmpty ?? true ? 'Obrigatório' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.valorReais ?? '',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Valor (R\$)',
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    onChanged: (v) => item.valorReais = v.trim().isEmpty ? null : v,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => setState(() => _itens.removeAt(idx)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total: ${formatoBRL(_itens.fold<int>(0, (s, i) => s + (i.valorCents ?? 0)))}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => context.pop(),
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