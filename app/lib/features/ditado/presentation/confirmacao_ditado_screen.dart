import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../../lancamentos/presentation/lancamento_form_validators.dart';
import '../application/ditado_providers.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';

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
  late DateTime _data;
  DateTime? _vencimento;
  bool _isSaving = false;
  CampoDitado? _gravandoCampo;
  CampoDitado? _processandoCampo;

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
    _data = DateTime.tryParse(rascunho.dataIso ?? '') ?? DateTime.now();
    _vencimento = DateTime.tryParse(rascunho.vencimentoIso ?? '');
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
        dataIso: _data.toIso8601String().substring(0, 10),
        vencimentoIso:
            _vencimento?.toIso8601String().substring(0, 10),
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
    final centavos = parseValorBRLParaCentavos(_valorController.text.trim())!;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lancamentosRepositoryProvider).create(
            descricao: _descricaoController.text.trim(),
            valorCents: centavos,
            categoria: _categoria,
            formaPagamento: _formaPagamento,
            data: _data,
            vencimento: _vencimento,
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