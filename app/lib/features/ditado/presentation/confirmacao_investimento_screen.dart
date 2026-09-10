import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../../lancamentos/domain/lancamento_converter.dart'
    show parseValorBRLParaCentavos, formatoData;
import '../../investimentos/application/investimentos_providers.dart';
import '../../investimentos/domain/investimento.dart';
import '../../investimentos/domain/movimento_investimento.dart';
import '../../investimentos/domain/rendimento_investimento.dart';
import '../domain/rascunho_investimento.dart';

class ConfirmacaoInvestimentoScreen extends ConsumerStatefulWidget {
  const ConfirmacaoInvestimentoScreen({super.key, required this.rascunho});

  final RascunhoInvestimento rascunho;

  @override
  ConsumerState<ConfirmacaoInvestimentoScreen> createState() =>
      _ConfirmacaoInvestimentoScreenState();
}

class _ConfirmacaoInvestimentoScreenState
    extends ConsumerState<ConfirmacaoInvestimentoScreen> {
  late final TextEditingController _quantidadeController;
  late final TextEditingController _precoController;
  late final TextEditingController _valorController;
  late final TextEditingController _dataController;
  late TipoClasseInvestimento? _classe;
  String? _nome;
  late OperacaoInvestimento? _operacao;
  DateTime? _data;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rascunho;
    _classe = r.classeEnum;
    _nome = r.nome;
    _operacao = r.operacaoEnum;
    _quantidadeController =
        TextEditingController(text: r.quantidade ?? '');
    _precoController =
        TextEditingController(text: r.precoUnitarioReais ?? '');
    _valorController = TextEditingController(text: r.valorReais ?? '');
    _data = r.dataIso != null ? DateTime.tryParse(r.dataIso!) : null;
    _dataController = TextEditingController(
      text: _data != null ? formatoData(_data!) : '',
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() {
        _data = picked;
        _dataController.text = formatoData(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ePorQuantidade = _classe?.ePorQuantidade ?? true;
    final isAporteResgate = _operacao == OperacaoInvestimento.aporte ||
        _operacao == OperacaoInvestimento.resgate;
    final isProvento =
        _operacao == OperacaoInvestimento.dividendo ||
            _operacao == OperacaoInvestimento.juros ||
            _operacao == OperacaoInvestimento.rendimento;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar investimento')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Classe
                  DropdownButtonFormField<TipoClasseInvestimento>(
                    initialValue: _classe,
                    decoration: const InputDecoration(
                      labelText: 'Classe do ativo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final c in TipoClasseInvestimento.values)
                        DropdownMenuItem(value: c, child: Text(c.rotulo)),
                    ],
                    onChanged: (v) {
                      setState(() => _classe = v);
                    },
                    validator: (v) =>
                        v == null ? 'Selecione a classe' : null,
                  ),
                  const SizedBox(height: 16),

                  // Nome do ativo
                  TextFormField(
                    initialValue: _nome,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nome do ativo (ex.: PETR4, CDB, Bitcoin)',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                    onChanged: (v) => _nome = v.trim().isEmpty ? null : v.trim(),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe o nome do ativo'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Operação
                  DropdownButtonFormField<OperacaoInvestimento>(
                    initialValue: _operacao,
                    decoration: const InputDecoration(
                      labelText: 'Operação',
                      prefixIcon: Icon(Icons.swap_horiz_outlined),
                    ),
                    items: [
                      for (final o in OperacaoInvestimento.values)
                        DropdownMenuItem(value: o, child: Text(o.rotulo)),
                    ],
                    onChanged: (v) {
                      setState(() => _operacao = v);
                    },
                    validator: (v) =>
                        v == null ? 'Selecione a operação' : null,
                  ),
                  const SizedBox(height: 16),

                  // Campos conforme tipo de operação
                  if (ePorQuantidade && !isProvento) ...[
                    // Compra/Venda: quantidade + preço unitário
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantidadeController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                            validator: (v) {
                              if (_operacao == OperacaoInvestimento.compra ||
                                  _operacao == OperacaoInvestimento.venda) {
                                final q = double.tryParse(
                                    v?.replaceAll(',', '.') ?? '');
                                if (q == null || q <= 0) {
                                  return 'Quantidade inválida';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _precoController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Preço unitário (R\$)',
                              prefixIcon: Icon(Icons.attach_money),
                              prefixText: 'R\$ ',
                            ),
                            validator: (v) {
                              if (_operacao == OperacaoInvestimento.compra ||
                                  _operacao == OperacaoInvestimento.venda) {
                                final p = parseValorBRLParaCentavos(v ?? '');
                                if (p == null || p <= 0) {
                                  return 'Preço inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (isAporteResgate) ...[
                    // Aporte/Resgate: apenas valor total
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            _operacao == OperacaoInvestimento.aporte
                                ? 'Valor do aporte (R\$'
                                : 'Valor do resgate (R\$)',
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'R\$ ',
                      ),
                      validator: (v) {
                        final p = parseValorBRLParaCentavos(v ?? '');
                        if (p == null || p <= 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ] else if (isProvento) ...[
                    // Dividendo/Juros/Rendimento: apenas valor total
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor recebido (R\$)',
                        prefixIcon: Icon(Icons.card_giftcard),
                        prefixText: 'R\$ ',
                      ),
                      validator: (v) {
                        final p = parseValorBRLParaCentavos(v ?? '');
                        if (p == null || p <= 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Data
                  TextFormField(
                    controller: _dataController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickData,
                    validator: (v) =>
                        _data == null ? 'Selecione a data' : null,
                  ),

                  const SizedBox(height: 24),

                  // Resumo do que será salvo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumo',
                            style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _linhaResumo('Classe', _classe?.rotulo ?? '—'),
                          _linhaResumo('Ativo', _nome ?? '—'),
                          _linhaResumo('Operação', _operacao?.rotulo ?? '—'),
                          if (ePorQuantidade && !isProvento) ...[
                            _linhaResumo('Quantidade',
                                _quantidadeController.text.isEmpty
                                    ? '—'
                                    : _quantidadeController.text),
                            _linhaResumo('Preço unit.',
                                _precoController.text.isEmpty
                                    ? '—'
                                    : 'R\$ ${_precoController.text}'),
                          ] else ...[
                            _linhaResumo('Valor',
                                _valorController.text.isEmpty
                                    ? '—'
                                    : 'R\$ ${_valorController.text}'),
                          ],
                          _linhaResumo('Data',
                              _dataController.text.isEmpty ? 'Hoje' : _dataController.text),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => context.pop(),
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
                        label: Text(_isSaving ? 'Salvando...' : 'Confirmar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaResumo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    // Validações básicas
    if (_classe == null) {
      _mostrarErro('Selecione a classe do ativo');
      return;
    }
    if (_nome == null || _nome!.isEmpty) {
      _mostrarErro('Informe o nome do ativo');
      return;
    }
    if (_operacao == null) {
      _mostrarErro('Selecione a operação');
      return;
    }

    final ePorQuantidade = _classe!.ePorQuantidade;
    final isProvento = _operacao == OperacaoInvestimento.dividendo ||
        _operacao == OperacaoInvestimento.juros ||
        _operacao == OperacaoInvestimento.rendimento;

    if (ePorQuantidade && !isProvento) {
      final q = double.tryParse(_quantidadeController.text.replaceAll(',', '.'));
      if (q == null || q <= 0) {
        _mostrarErro('Quantidade inválida');
        return;
      }
      final p = parseValorBRLParaCentavos(_precoController.text);
      if (p == null || p <= 0) {
        _mostrarErro('Preço unitário inválido');
        return;
      }
    } else {
      final v = parseValorBRLParaCentavos(_valorController.text);
      if (v == null || v <= 0) {
        _mostrarErro('Valor inválido');
        return;
      }
    }

    _data ??= DateTime.now();

    setState(() => _isSaving = true);

    try {
      final investimentosRepo = ref.read(investimentosRepositoryProvider);
      final movimentosRepo = ref.read(movimentosInvestimentoRepositoryProvider);
      final rendimentosRepo =
          ref.read(rendimentosInvestimentoRepositoryProvider);

      // Busca ou cria o ativo
      final investimentos = ref
          .read(investimentosStreamProvider)
          .value;
      Investimento? investimento;
      if (investimentos != null) {
        for (final inv in investimentos) {
          if (inv.nome.toLowerCase() == _nome!.toLowerCase() &&
              inv.classe == _classe) {
            investimento = inv;
            break;
          }
        }
      }

      String investimentoId;
      if (investimento != null) {
        investimentoId = investimento.id;
      } else {
        // Cria novo ativo
        final novo = await investimentosRepo.create(Investimento(
          id: '',
          classe: _classe!,
          nome: _nome!,
          quantidade: ePorQuantidade ? 0.0 : 0.0,
          precoAtualCents: ePorQuantidade ? 0 : 0,
          saldoCents: !ePorQuantidade ? 0 : 0,
        ));
        investimentoId = novo.id;
      }

      // Cria movimento ou rendimento conforme operação
      if (isProvento) {
        // Rendimento (dividendo/juros/rendimento)
        final valor = parseValorBRLParaCentavos(_valorController.text)!;
        await rendimentosRepo.create(RendimentoInvestimento(
          id: '',
          investimentoId: investimentoId,
          tipo: switch (_operacao!) {
            OperacaoInvestimento.dividendo =>
              TipoRendimentoInvestimento.dividendo,
            OperacaoInvestimento.juros =>
              TipoRendimentoInvestimento.juros,
            OperacaoInvestimento.rendimento =>
              TipoRendimentoInvestimento.rendimento,
            _ => TipoRendimentoInvestimento.outro,
          },
          valorCents: valor,
          data: _data!,
        ));
      } else {
        // Movimento (compra/venda/aporte/resgate)
        TipoMovimentoInvestimento tipoMovimento;
        double quantidade;
        int precoUnitCents;

        if (ePorQuantidade) {
          // Compra/Venda
          tipoMovimento = _operacao == OperacaoInvestimento.compra
              ? TipoMovimentoInvestimento.compra
              : TipoMovimentoInvestimento.venda;
          quantidade = double.parse(
              _quantidadeController.text.replaceAll(',', '.'));
          precoUnitCents = parseValorBRLParaCentavos(_precoController.text)!;
        } else {
          // Aporte/Resgate
          tipoMovimento = _operacao == OperacaoInvestimento.aporte
              ? TipoMovimentoInvestimento.compra
              : TipoMovimentoInvestimento.venda;
          quantidade = 1.0;
          precoUnitCents = parseValorBRLParaCentavos(_valorController.text)!;
        }

        await movimentosRepo.create(MovimentoInvestimento(
          id: '',
          investimentoId: investimentoId,
          tipo: tipoMovimento,
          quantidade: quantidade,
          precoUnitCents: precoUnitCents,
          data: _data!,
        ));

        // Atualiza posição do ativo
        await _atualizarPosicao(investimentoId, tipoMovimento, quantidade,
            precoUnitCents, ePorQuantidade);
      }

      if (mounted) context.go(AppRoutes.investimentos);
    } catch (e) {
      debugPrint('Erro ao salvar investimento: $e');
      if (!mounted) return;
      _mostrarErro('Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _atualizarPosicao(
    String investimentoId,
    TipoMovimentoInvestimento tipoMovimento,
    double quantidade,
    int precoUnitCents,
    bool ePorQuantidade,
  ) async {
    final repo = ref.read(investimentosRepositoryProvider);
    final investimentos = ref.read(investimentosStreamProvider).value;
    if (investimentos == null) return;

    Investimento? atual;
    for (final inv in investimentos) {
      if (inv.id == investimentoId) {
        atual = inv;
        break;
      }
    }
    if (atual == null) return;

    double novaQuantidade = atual.quantidade;
    int novoPrecoAtual = atual.precoAtualCents;
    int novoSaldo = atual.saldoCents;

    if (ePorQuantidade) {
      if (tipoMovimento == TipoMovimentoInvestimento.compra) {
        novaQuantidade = atual.quantidade + quantidade;
        novoPrecoAtual = precoUnitCents;
      } else {
        novaQuantidade = (atual.quantidade - quantidade).clamp(0, 1 << 62).toDouble();
        // preço mantém o último preço de compra ou zera se quantidade for 0
        if (novaQuantidade == 0) novoPrecoAtual = 0;
      }
    } else {
      // RF/Banco Digital: aporte = compra, resgate = venda
      if (tipoMovimento == TipoMovimentoInvestimento.compra) {
        novoSaldo += precoUnitCents;
      } else {
        novoSaldo = (atual.saldoCents - precoUnitCents).clamp(0, 1 << 62);
      }
    }

    await repo.update(Investimento(
      id: atual.id,
      classe: atual.classe,
      nome: atual.nome,
      quantidade: ePorQuantidade ? novaQuantidade : atual.quantidade,
      precoAtualCents: ePorQuantidade ? novoPrecoAtual : atual.precoAtualCents,
      saldoCents: !ePorQuantidade ? novoSaldo : atual.saldoCents,
    ));
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}