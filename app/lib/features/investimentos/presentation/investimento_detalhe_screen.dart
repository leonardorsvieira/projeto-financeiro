import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';
import '../domain/movimento_investimento.dart';

/// Detalhe de um ativo: posição resumida, lista de movimentos e registro de
/// novas compras/vendas (que atualizam a posição).
class InvestimentoDetalheScreen extends ConsumerStatefulWidget {
  const InvestimentoDetalheScreen({
    super.key,
    required this.investimentoId,
  });

  final String investimentoId;

  @override
  ConsumerState<InvestimentoDetalheScreen> createState() =>
      _InvestimentoDetalheScreenState();
}

class _InvestimentoDetalheScreenState
    extends ConsumerState<InvestimentoDetalheScreen> {
  Investimento? _getInvestimento(List<Investimento>? lista) {
    if (lista == null) return null;
    for (final i in lista) {
      if (i.id == widget.investimentoId) return i;
    }
    return null;
  }

  Future<void> _abrirDialog(
    Investimento investimento,
    List<MovimentoInvestimento> movimentos,
  ) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MovimentoDialog(investimento: investimento),
    );
    if (resultado == null || !mounted) return;

    final tipo = resultado['tipo'] as TipoMovimentoInvestimento;
    final quantidade = resultado['quantidade'] as double;
    final precoUnitCents = resultado['precoUnitCents'] as int;
    final data = resultado['data'] as DateTime;

    // Impede venda que deixaria a quantidade negativa.
    if (tipo == TipoMovimentoInvestimento.venda &&
        investimento.ePorQuantidade &&
        quantidade > investimento.quantidade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A venda não pode ser maior que a quantidade atual.'),
        ),
      );
      return;
    }

    try {
      final repos = ref.read(investimentosRepositoryProvider);
      final movRepo = ref.read(movimentosInvestimentoRepositoryProvider);

      await movRepo.create(
        MovimentoInvestimento(
          id: '',
          investimentoId: investimento.id,
          tipo: tipo,
          quantidade: quantidade,
          precoUnitCents: precoUnitCents,
          data: data,
        ),
      );

      // Atualiza posição: quantidade +/− e preço unitário atual.
      double novaQuantidade = investimento.quantidade;
      if (investimento.ePorQuantidade) {
        novaQuantidade = tipo == TipoMovimentoInvestimento.compra
            ? investimento.quantidade + quantidade
            : investimento.quantidade - quantidade;
      }
      await repos.update(
        Investimento(
          id: investimento.id,
          classe: investimento.classe,
          nome: investimento.nome,
          quantidade:
              investimento.ePorQuantidade ? novaQuantidade : investimento.quantidade,
          precoAtualCents: investimento.ePorQuantidade
              ? precoUnitCents
              : investimento.precoAtualCents,
          saldoCents: !investimento.ePorQuantidade
              ? tipo == TipoMovimentoInvestimento.compra
                  ? investimento.saldoCents + precoUnitCents
                  : (investimento.saldoCents - precoUnitCents)
                      .clamp(0, 1 << 62)
              : investimento.saldoCents,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar o movimento.')),
      );
    }
  }

  Future<void> _excluirComConfirmacao(MovimentoInvestimento movimento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir movimento?'),
        content: const Text(
          'O movimento será removido do histórico. Essa ação não pode ser desfeita.',
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
          .read(movimentosInvestimentoRepositoryProvider)
          .delete(movimento.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir o movimento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final investimentos = ref.watch(investimentosStreamProvider).value ?? [];
    final investimento = _getInvestimento(investimentos);
    final movimentos =
        ref.watch(movimentosPorInvestimentoProvider(widget.investimentoId)).value ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: Text(investimento?.nome ?? 'Investimento'),
      ),
      floatingActionButton: investimento == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirDialog(investimento, movimentos),
              icon: const Icon(Icons.add),
              label: const Text('Movimento'),
            ),
      body: investimento == null
          ? const Center(child: Text('Ativo não encontrado.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumoInvestimento(investimento: investimento),
                const SizedBox(height: 24),
                Text(
                  'Movimentos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (movimentos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Nenhum movimento registrado.')),
                  )
                else
                  for (final mov in movimentos)
                    _MovimentoTile(
                      movimento: mov,
                      ePorQuantidade: investimento.ePorQuantidade,
                      onExcluir: () => _excluirComConfirmacao(mov),
                    ),
              ],
            ),
    );
  }
}

class _ResumoInvestimento extends StatelessWidget {
  const _ResumoInvestimento({required this.investimento});

  final Investimento investimento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detalhe = investimento.ePorQuantidade
        ? '${investimento.quantidade.toStringAsFixed(2)} un · '
            '${formatoBRL(investimento.precoAtualCents)}/un'
        : investimento.classe.rotulo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investimento.classe.rotulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Patrimônio: ${formatoBRL(investimento.patrimonioCents)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(detalhe, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MovimentoTile extends StatelessWidget {
  const _MovimentoTile({
    required this.movimento,
    required this.ePorQuantidade,
    required this.onExcluir,
  });

  final MovimentoInvestimento movimento;
  final bool ePorQuantidade;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ehCompra = movimento.tipo == TipoMovimentoInvestimento.compra;
    final cor = ehCompra ? Colors.green.shade700 : theme.colorScheme.error;
    final rotulo = ePorQuantidade
        ? '${movimento.tipo.rotulo} · '
            '${movimento.quantidade.toStringAsFixed(2)} un'
        : (ehCompra ? 'Aporte' : 'Resgate');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.12),
          child: Icon(
            ehCompra ? Icons.add : Icons.remove,
            color: cor,
          ),
        ),
        title: Text(rotulo),
        subtitle: Text(formatoData(movimento.data)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (ehCompra ? '' : '-') + formatoBRL(movimento.valorCents),
              style: theme.textTheme.titleMedium?.copyWith(
                color: cor,
                fontWeight: FontWeight.w700,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações',
              onSelected: (value) {
                if (value == 'excluir') onExcluir();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MovimentoDialog extends StatefulWidget {
  const _MovimentoDialog({required this.investimento});

  final Investimento investimento;

  @override
  State<_MovimentoDialog> createState() => _MovimentoDialogState();
}

class _MovimentoDialogState extends State<_MovimentoDialog> {
  late final TextEditingController _quantidadeController;
  late final TextEditingController _precoController;
  late TipoMovimentoInvestimento _tipo;
  late DateTime _data;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tipo = TipoMovimentoInvestimento.compra;
    _data = DateTime.now();
    _quantidadeController = TextEditingController(
      text: widget.investimento.ePorQuantidade ? '1' : '1',
    );
    _precoController = TextEditingController();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
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
    final preco = parseValorBRLParaCentavos(_precoController.text);
    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor/preço válido.')),
      );
      return;
    }
    final quantidade = double.tryParse(
      _quantidadeController.text.trim().replaceAll(',', '.'),
    );
    if (quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    // Para RF/bco a "quantidade" do movimento é sempre 1 e o preço é o valor
    // financeiro em centavos (aporte/resgate).
    final precoUnitCents = widget.investimento.ePorQuantidade
        ? preco
        : preco;
    Navigator.pop(context, {
      'tipo': _tipo,
      'quantidade': widget.investimento.ePorQuantidade ? quantidade : 1.0,
      'precoUnitCents': precoUnitCents,
      'data': _data,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ePorQuantidade = widget.investimento.ePorQuantidade;
    final tituloCompra = ePorQuantidade ? 'Compra' : 'Aporte';
    final tituloVenda = ePorQuantidade ? 'Venda' : 'Resgate';

    return AlertDialog(
      title: Text('Novo movimento — ${widget.investimento.nome}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TipoMovimentoInvestimento>(
              segments: [
                ButtonSegment(
                  value: TipoMovimentoInvestimento.compra,
                  label: Text(tituloCompra),
                ),
                ButtonSegment(
                  value: TipoMovimentoInvestimento.venda,
                  label: Text(tituloVenda),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 16),
            if (ePorQuantidade) ...[
              TextField(
                controller: _quantidadeController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                labelText: ePorQuantidade
                    ? 'Preço unitário (R\$)'
                    : 'Valor aplicado (R\$)',
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
          ],
        ),
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
