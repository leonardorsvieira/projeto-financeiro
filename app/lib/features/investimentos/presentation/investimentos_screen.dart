import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';

class InvestimentosScreen extends ConsumerStatefulWidget {
  const InvestimentosScreen({super.key});

  @override
  ConsumerState<InvestimentosScreen> createState() => _InvestimentosScreenState();
}

class _InvestimentosScreenState extends ConsumerState<InvestimentosScreen> {
  Future<void> _salvar({
    Investimento? investimento,
    required TipoClasseInvestimento classe,
    required String nome,
    required double quantidade,
    required int precoAtualCents,
    required int saldoCents,
  }) async {
    final repo = ref.read(investimentosRepositoryProvider);
    if (investimento == null) {
      await repo.create(
        Investimento(
          id: '',
          classe: classe,
          nome: nome,
          quantidade: quantidade,
          precoAtualCents: precoAtualCents,
          saldoCents: saldoCents,
        ),
      );
    } else {
      await repo.update(
        Investimento(
          id: investimento.id,
          classe: classe,
          nome: nome,
          quantidade: quantidade,
          precoAtualCents: precoAtualCents,
          saldoCents: saldoCents,
        ),
      );
    }
  }

  Future<void> _abrirDialog({Investimento? investimento}) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _InvestimentoFormDialog(investimento: investimento),
    );
    if (resultado == null || !mounted) return;
    try {
      await _salvar(
        investimento: investimento,
        classe: resultado['classe'] as TipoClasseInvestimento,
        nome: resultado['nome'] as String,
        quantidade: resultado['quantidade'] as double,
        precoAtualCents: resultado['precoAtualCents'] as int,
        saldoCents: resultado['saldoCents'] as int,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar o ativo.')),
      );
    }
  }

  Future<void> _excluirComConfirmacao(Investimento investimento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ativo?'),
        content: Text(
          'O ativo "${investimento.nome}" será removido, junto com seus movimentos e rendimentos. Essa ação não pode ser desfeita.',
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
      await ref.read(investimentosRepositoryProvider).delete(investimento.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir o ativo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final porClasse = ref.watch(investimentosPorClasseProvider);
    final patrimonio = ref.watch(patrimonioTotalProvider);
    final rendimento = ref.watch(rendimentoAcumuladoProvider);
    final custoTotal = ref.watch(custoTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            tooltip: 'Rendimentos por mês',
            icon: const Icon(Icons.card_giftcard),
            onPressed: () => context.push(AppRoutes.rendimentos),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Novo ativo'),
      ),
      body: porClasse.totalAtivos == 0
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PatrimonioCard(
                  patrimonioCents: patrimonio,
                  rendimentoCents: rendimento,
                  custoCents: custoTotal,
                ),
                const SizedBox(height: 16),
                for (final grupo in porClasse.grupos) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      grupo.classe.rotulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  for (final investimento in grupo.investimentos)
                    _InvestimentoTile(
                      investimento: investimento,
                      onTap: () => context.push(
                        AppRoutes.investimentoDetalheDe(investimento.id),
                      ),
                      onEditar: () =>
                          _abrirDialog(investimento: investimento),
                      onExcluir: () =>
                          _excluirComConfirmacao(investimento),
                    ),
                ],
              ],
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
                  Icons.pie_chart_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum ativo cadastrado',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cadastre ações, FIIs, cripto, renda fixa ou contas de banco digital para acompanhar seu patrimônio.',
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

class _PatrimonioCard extends StatelessWidget {
  const _PatrimonioCard({
    required this.patrimonioCents,
    required this.rendimentoCents,
    required this.custoCents,
  });

  final int patrimonioCents;
  final int rendimentoCents;
  final int custoCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positivo = rendimentoCents >= 0;
    final corRendimento =
        positivo ? Colors.green.shade700 : theme.colorScheme.error;
    final pct = custoCents > 0
        ? (rendimentoCents / custoCents * 100).abs().round()
        : 0;
    final textoPct = custoCents > 0
        ? '${positivo ? '+' : '-'}$pct%'
        : '—';

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimônio total',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatoBRL(patrimonioCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  positivo ? Icons.trending_up : Icons.trending_down,
                  color: corRendimento,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${positivo ? '+' : '-'}'
                  '${formatoBRL(rendimentoCents.abs())} '
                  '($textoPct)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: corRendimento,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestimentoTile extends StatelessWidget {
  const _InvestimentoTile({
    required this.investimento,
    required this.onTap,
    required this.onEditar,
    required this.onExcluir,
  });

  final Investimento investimento;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  String _subtitle() {
    if (investimento.ePorQuantidade) {
      final qtd = investimento.quantidade.toStringAsFixed(
        investimento.quantidade == investimento.quantidade.roundToDouble()
            ? 0
            : 2,
      );
      return '$qtd ${investimento.classe.rotulo}'
          ' · ${formatoBRL(investimento.precoAtualCents)}';
    }
    return investimento.classe.rotulo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.trending_up,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(investimento.nome),
        subtitle: Text(_subtitle()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatoBRL(investimento.patrimonioCents),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _InvestimentoFormDialog extends StatefulWidget {
  const _InvestimentoFormDialog({this.investimento});

  final Investimento? investimento;

  @override
  State<_InvestimentoFormDialog> createState() => _InvestimentoFormDialogState();
}

class _InvestimentoFormDialogState extends State<_InvestimentoFormDialog> {
  late final TextEditingController _nomeController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _precoController;
  late final TextEditingController _saldoController;
  late TipoClasseInvestimento _classe;
  bool _isSaving = false;

  bool get _editando => widget.investimento != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.investimento;
    _classe = inv?.classe ?? TipoClasseInvestimento.acao;
    _nomeController = TextEditingController(text: inv?.nome ?? '');
    _quantidadeController = TextEditingController(
      text: (inv?.quantidade ?? 0) == 0
          ? ''
          : (inv!.quantidade.toStringAsFixed(2)),
    );
    _precoController = TextEditingController(
      text: (inv != null && inv.ePorQuantidade)
          ? _semPrefixo(formatoBRL(inv.precoAtualCents))
          : '',
    );
    _saldoController = TextEditingController(
      text: (inv != null && !inv.ePorQuantidade)
          ? _semPrefixo(formatoBRL(inv.saldoCents))
          : '',
    );
  }

  String _semPrefixo(String valor) =>
      valor.replaceAll('R\$', '').trim();

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do ativo.')),
      );
      return;
    }

    final quantidade = _classe.ePorQuantidade
        ? double.tryParse(
            _quantidadeController.text.trim().replaceAll(',', '.'),
          )
        : 0.0;
    if (_classe.ePorQuantidade &&
        (quantidade == null || quantidade < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida.')),
      );
      return;
    }

    final precoAtualCents = _classe.ePorQuantidade
        ? parseValorBRLParaCentavos(_precoController.text)
        : 0;
    if (_classe.ePorQuantidade && precoAtualCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um preço válido.')),
      );
      return;
    }

    final saldoCents = _classe.ePorQuantidade
        ? 0
        : parseValorBRLParaCentavos(_saldoController.text);
    if (!_classe.ePorQuantidade && saldoCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um saldo válido.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context, {
      'classe': _classe,
      'nome': nome,
      'quantidade': quantidade!,
      'precoAtualCents': precoAtualCents!,
      'saldoCents': saldoCents!,
    });
  }

  @override
  Widget build(BuildContext context) {
    final porQuantidade = _classe.ePorQuantidade;
    return AlertDialog(
      title: Text(_editando ? 'Editar ativo' : 'Novo ativo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TipoClasseInvestimento>(
              initialValue: _classe,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: [
                for (final c in TipoClasseInvestimento.values)
                  DropdownMenuItem(value: c, child: Text(c.rotulo)),
              ],
              onChanged: (v) => setState(() => _classe = v ?? _classe),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            if (porQuantidade) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _quantidadeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preço atual',
                  prefixText: 'R\$ ',
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              TextField(
                controller: _saldoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Saldo atual',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
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
