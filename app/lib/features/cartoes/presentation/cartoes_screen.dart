import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/cartoes_providers.dart';
import '../domain/cartao_credito.dart';

void abrirGerenciadorCartoes(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const CartoesScreen(),
  );
}

class CartoesScreen extends ConsumerWidget {
  const CartoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartoesState = ref.watch(cartoesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cartões de Crédito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo Cartão',
            onPressed: () => _abrirDialogoFormulario(context, ref, null),
          ),
        ],
      ),
      body: cartoesState.when(
        data: (cartoes) {
          if (cartoes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card_off_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum cartão cadastrado.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _abrirDialogoFormulario(context, ref, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Cartão'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartoes.length,
            itemBuilder: (context, index) {
              final c = cartoes[index];
              Color cardColor;
              try {
                cardColor = Color(int.parse(c.corHex.replaceFirst('#', '0xFF')));
              } catch (_) {
                cardColor = theme.colorScheme.primary;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [cardColor.withValues(alpha: 0.9), cardColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                c.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (val) {
                              if (val == 'editar') {
                                _abrirDialogoFormulario(context, ref, c);
                              } else if (val == 'excluir') {
                                ref
                                    .read(cartoesControllerProvider.notifier)
                                    .excluirCartao(c.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fechamento',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  'Dia ${c.diaFechamento}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vencimento',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  'Dia ${c.diaVencimento}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (c.validadeMMYY != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Validade',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    c.validadeMMYY!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (c.limiteCents != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Limite: ${formatoBRL(c.limiteCents!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _abrirDialogoFormulario(
      BuildContext context, WidgetRef ref, CartaoCredito? cartao) {
    showDialog(
      context: context,
      builder: (context) => _FormularioCartaoDialog(cartao: cartao),
    );
  }
}

class _FormularioCartaoDialog extends ConsumerStatefulWidget {
  const _FormularioCartaoDialog({this.cartao});

  final CartaoCredito? cartao;

  @override
  ConsumerState<_FormularioCartaoDialog> createState() =>
      __FormularioCartaoDialogState();
}

class __FormularioCartaoDialogState
    extends ConsumerState<_FormularioCartaoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _fechamentoCtrl;
  late final TextEditingController _vencimentoCtrl;
  late final TextEditingController _validadeCtrl;
  late final TextEditingController _limiteCtrl;
  String _corHex = '#8A05BE';

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.cartao?.nome ?? '');
    _fechamentoCtrl = TextEditingController(
        text: widget.cartao?.diaFechamento.toString() ?? '5');
    _vencimentoCtrl = TextEditingController(
        text: widget.cartao?.diaVencimento.toString() ?? '12');
    _validadeCtrl =
        TextEditingController(text: widget.cartao?.validadeMMYY ?? '');
    _limiteCtrl = TextEditingController(
        text: widget.cartao?.limiteCents != null
            ? (widget.cartao!.limiteCents! / 100).toStringAsFixed(2)
            : '');
    _corHex = widget.cartao?.corHex ?? '#8A05BE';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _fechamentoCtrl.dispose();
    _vencimentoCtrl.dispose();
    _validadeCtrl.dispose();
    _limiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cartao != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Cartão' : 'Novo Cartão de Crédito'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cartão (ex: Nubank, Inter)',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fechamentoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fechamento (dia)',
                      ),
                      validator: (val) {
                        final d = int.tryParse(val ?? '');
                        if (d == null || d < 1 || d > 31) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _vencimentoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vencimento (dia)',
                      ),
                      validator: (val) {
                        final d = int.tryParse(val ?? '');
                        if (d == null || d < 1 || d > 31) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _validadeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Validade (opcional: MM/AA)',
                  hintText: 'ex: 12/28',
                  prefixIcon: Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limiteCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Limite (opcional)',
                  prefixText: r'R$ ',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final fechamento = int.parse(_fechamentoCtrl.text.trim());
              final vencimento = int.parse(_vencimentoCtrl.text.trim());
              final limiteCents = _limiteCtrl.text.trim().isNotEmpty
                  ? (double.parse(_limiteCtrl.text.trim().replaceAll(',', '.')) *
                          100)
                      .round()
                  : null;

              final novoCartao = CartaoCredito(
                id: widget.cartao?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                nome: _nomeCtrl.text.trim(),
                diaFechamento: fechamento,
                diaVencimento: vencimento,
                validadeMMYY: _validadeCtrl.text.trim().isNotEmpty
                    ? _validadeCtrl.text.trim()
                    : null,
                limiteCents: limiteCents,
                corHex: _corHex,
              );

              ref
                  .read(cartoesControllerProvider.notifier)
                  .salvarCartao(novoCartao);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
