import '../../../theme/caderneta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/icones.dart';
import '../../home/domain/app_routes.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/investimentos_providers.dart';
import '../domain/investimento.dart';

import 'rebalanceamento_dialog.dart';

/// Patrimônio: só leitura. Os ativos e valores vêm do Open Finance e são
/// atualizados pela sincronização da Pluggy.
class InvestimentosScreen extends ConsumerStatefulWidget {
  const InvestimentosScreen({super.key});

  @override
  ConsumerState<InvestimentosScreen> createState() =>
      _InvestimentosScreenState();
}

class _InvestimentosScreenState extends ConsumerState<InvestimentosScreen> {
  /// false = agrupado por classe; true = do que mais rendeu ao que mais perdeu.
  bool _porRendimento = false;

  void _abrir(Investimento investimento) =>
      context.push(AppRoutes.investimentoDetalheDe(investimento.id));

  @override
  Widget build(BuildContext context) {
    final porClasse = ref.watch(investimentosPorClasseProvider);
    final patrimonio = ref.watch(patrimonioTotalProvider);
    final resumo = ref.watch(resumoRendimentosProvider);
    final theme = Theme.of(context);

    Widget titulo(String texto) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        texto,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final todos = [for (final g in porClasse.grupos) ...g.investimentos];
    final semDado = todos.where((i) => i.valorInvestidoCents == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            tooltip: _porRendimento
                ? 'Agrupar por classe'
                : 'Ordenar por rendimento',
            icon: PhosphorIcon(_porRendimento ? Icones.categoria : Icones.ranking),
            onPressed: () => setState(() => _porRendimento = !_porRendimento),
          ),
          IconButton(
            tooltip: 'Calculadora de Rebalanceamento',
            icon: const PhosphorIcon(Icones.rebalancear),
            onPressed: () => mostrarDialogoRebalanceamento(context),
          ),
        ],
      ),
      body: porClasse.totalAtivos == 0
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PatrimonioCard(patrimonioCents: patrimonio, resumo: resumo),
                if (resumo.maiorGanho != null || resumo.maiorPerda != null) ...[
                  const SizedBox(height: 12),
                  _DestaquesCard(resumo: resumo, onTap: _abrir),
                ],
                const SizedBox(height: 16),
                if (_porRendimento) ...[
                  titulo('Do que mais rendeu ao que mais perdeu'),
                  for (final (i, investimento) in resumo.ranking.indexed)
                    _InvestimentoTile(
                      investimento: investimento,
                      posicao: i + 1,
                      onTap: () => _abrir(investimento),
                    ),
                  if (semDado.isNotEmpty) ...[
                    titulo('Sem valor aplicado informado'),
                    for (final investimento in semDado)
                      _InvestimentoTile(
                        investimento: investimento,
                        onTap: () => _abrir(investimento),
                      ),
                  ],
                ] else
                  for (final grupo in porClasse.grupos) ...[
                    titulo(grupo.classe.rotulo),
                    for (final investimento in grupo.investimentos)
                      _InvestimentoTile(
                        investimento: investimento,
                        onTap: () => _abrir(investimento),
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
                PhosphorIcon(
                  Icones.patrimonio,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum investimento encontrado',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Seus investimentos aparecem aqui automaticamente, vindos '
                  'dos bancos conectados no Open Finance.',
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

/// "+R$ 12,34 (+5,6%)" / "-R$ 12,34 (-5,6%)".
String textoRendimento(int cents, double? percent) {
  final sinal = cents >= 0 ? '+' : '-';
  final pct = percent == null
      ? ''
      : ' ($sinal${percent.abs().toStringAsFixed(1).replaceAll('.', ',')}%)';
  return '$sinal${formatoBRL(cents.abs())}$pct';
}

Color corRendimento(BuildContext context, int cents) =>
    cents >= 0 ? Caderneta.corReceita(context) : Theme.of(context).colorScheme.error;

class _PatrimonioCard extends StatelessWidget {
  const _PatrimonioCard({required this.patrimonioCents, required this.resumo});

  final int patrimonioCents;
  final ResumoRendimentos resumo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final naCor = theme.colorScheme.onPrimaryContainer;
    final temDado = resumo.ranking.isNotEmpty;

    Widget linha(String rotulo, String valor, {Color? cor}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: theme.textTheme.bodyMedium?.copyWith(color: naCor),
          ),
          Text(
            valor,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cor ?? naCor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimônio total',
              style: theme.textTheme.titleSmall?.copyWith(color: naCor),
            ),
            const SizedBox(height: 4),
            Text(
              formatoBRL(patrimonioCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: naCor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (temDado) ...[
              const SizedBox(height: 8),
              linha('Total aplicado', formatoBRL(resumo.investidoCents)),
              linha('Valor atual', formatoBRL(resumo.atualCents)),
              linha(
                resumo.rendimentoCents >= 0 ? 'Rendeu' : 'Perdeu',
                textoRendimento(
                  resumo.rendimentoCents,
                  resumo.rentabilidadePercent,
                ),
                cor: corRendimento(context, resumo.rendimentoCents),
              ),
            ],
            if (resumo.semValorInvestido > 0) ...[
              const SizedBox(height: 8),
              Text(
                temDado
                    ? '${resumo.semValorInvestido} ativo(s) sem valor aplicado '
                          'informado pelo banco não entram no rendimento.'
                    : 'O banco não informou o valor aplicado, então não dá '
                          'para calcular o rendimento.',
                style: theme.textTheme.bodySmall?.copyWith(color: naCor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestaquesCard extends StatelessWidget {
  const _DestaquesCard({required this.resumo, required this.onTap});

  final ResumoRendimentos resumo;
  final void Function(Investimento) onTap;

  @override
  Widget build(BuildContext context) {
    Widget destaque(String rotulo, IconData icone, Investimento inv) {
      final cor = corRendimento(context, inv.rendimentoCents!);
      return ListTile(
        onTap: () => onTap(inv),
        leading: PhosphorIcon(icone, color: cor),
        title: Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
        subtitle: Text(
          inv.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: Text(
          textoRendimento(inv.rendimentoCents!, inv.rentabilidadePercent),
          style: TextStyle(color: cor, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          if (resumo.maiorGanho case final g?)
            destaque('Mais rendeu', Icones.trofeu, g),
          if (resumo.maiorPerda case final p?)
            destaque('Mais perdeu', Icones.desce, p),
        ],
      ),
    );
  }
}

class _InvestimentoTile extends StatelessWidget {
  const _InvestimentoTile({
    required this.investimento,
    required this.onTap,
    this.posicao,
  });

  final Investimento investimento;
  final VoidCallback onTap;

  /// Posição no ranking de rendimento (null na visão por classe).
  final int? posicao;

  String get _subtitle {
    final partes = <String>[];
    if (investimento.ePorQuantidade) {
      final qtd = investimento.quantidade.toStringAsFixed(
        investimento.quantidade == investimento.quantidade.roundToDouble()
            ? 0
            : 2,
      );
      partes.add('$qtd un · ${formatoBRL(investimento.precoAtualCents)}');
    } else if (posicao != null) {
      partes.add(investimento.classe.rotulo);
    }
    final investido = investimento.valorInvestidoCents;
    partes.add(
      investido == null
          ? 'Aplicado: não informado'
          : 'Aplicado: ${formatoBRL(investido)}',
    );
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rendimento = investimento.rendimentoCents;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: posicao != null
              ? Text(
                  '$posicao',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : PhosphorIcon(
                  Icones.rendimento,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
        ),
        title: Text(investimento.nome),
        subtitle: Text(_subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatoBRL(investimento.patrimonioCents),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (rendimento != null)
              Text(
                textoRendimento(rendimento, investimento.rentabilidadePercent),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: corRendimento(context, rendimento),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
