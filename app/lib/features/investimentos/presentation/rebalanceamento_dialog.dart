import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';

/// Modal interativo da Calculadora de Rebalanceamento de Carteira.
void mostrarDialogoRebalanceamento(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _RebalanceamentoModal(),
  );
}

class _RebalanceamentoModal extends ConsumerStatefulWidget {
  const _RebalanceamentoModal();

  @override
  ConsumerState<_RebalanceamentoModal> createState() =>
      __RebalanceamentoModalState();
}

class __RebalanceamentoModalState
    extends ConsumerState<_RebalanceamentoModal> {
  final _aporteController = TextEditingController(text: '1000,00');
  int _aporteCents = 100000;
  bool _editandoMetas = false;
  late Map<TipoClasseInvestimento, TextEditingController> _metaControllers;

  @override
  void initState() {
    super.initState();
    final metas = ref.read(metasAlocacaoProvider);
    _metaControllers = {
      for (final c in TipoClasseInvestimento.values)
        c: TextEditingController(text: (metas[c] ?? 0.0).toStringAsFixed(0)),
    };
  }

  @override
  void dispose() {
    _aporteController.dispose();
    for (final c in _metaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _atualizarAporte(String value) {
    final limpo = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _aporteCents = int.tryParse(limpo) ?? 0;
    });
  }

  void _salvarMetas() {
    final novasMetas = <TipoClasseInvestimento, double>{};
    for (final entry in _metaControllers.entries) {
      novasMetas[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }
    ref.read(metasAlocacaoProvider.notifier).salvarMetas(novasMetas);
    setState(() {
      _editandoMetas = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metas de alocação salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtBrl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
    final sugestoes = ref.watch(rebalanceamentoSugestoesProvider(_aporteCents));
    final metas = ref.watch(metasAlocacaoProvider);

    final somaMetas = metas.values.fold(0.0, (sum, v) => sum + v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Rebalanceamento'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_editandoMetas ? Icons.check : Icons.tune),
            tooltip: _editandoMetas ? 'Salvar Metas' : 'Ajustar Metas %',
            onPressed: () {
              if (_editandoMetas) {
                _salvarMetas();
              } else {
                setState(() {
                  _editandoMetas = true;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de Aporte
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Valor para Aportar (R\$)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aporteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: r'R$ ',
                      border: OutlineInputBorder(),
                      hintText: '0,00',
                    ),
                    onChanged: _atualizarAporte,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A calculadora sugere a distribuição exata para aproximar sua carteira das metas percentuais sem precisar vender ativos.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Se estiver no modo de edição das Metas %
          if (_editandoMetas) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Metas de Alocação por Classe',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('Total: ${somaMetas.toStringAsFixed(0)}%'),
                          backgroundColor: (somaMetas == 100)
                              ? Colors.green.shade100
                              : theme.colorScheme.errorContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final classe in TipoClasseInvestimento.values) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(classe.rotulo)),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _metaControllers[classe],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _salvarMetas,
                        child: const Text('Salvar Metas %'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lista de Sugestões por Classe
          Text(
            'Recomendação de Aporte por Classe',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in sugestoes) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.classe.rotulo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.valorSugeridoCents > 0
                                ? Colors.green.shade100
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.valorSugeridoCents > 0
                                ? '+ ${fmtBrl.format(s.valorSugeridoReais)}'
                                : 'Sem Aporte',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: s.valorSugeridoCents > 0
                                  ? Colors.green.shade800
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patrimônio: ${fmtBrl.format(s.patrimonioAtualReais)} (${s.percentualAtual.toStringAsFixed(1)}%)',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Meta: ${s.percentualAlvo.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (s.percentualAlvo > 0)
                          ? (s.percentualAtual / s.percentualAlvo)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                      color: s.percentualAtual < s.percentualAlvo
                          ? Colors.green.shade600
                          : theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
