import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../ditado/application/ditado_providers.dart';
import '../../home/domain/app_routes.dart';
import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../../metas/application/metas_providers.dart';
import '../application/dashboard_providers.dart';

/// Cores do donut por categoria (fallback para categorias novas).
const _coresCategorias = <String, Color>{
  'Alimentação': Color(0xFFE53935),
  'Transporte': Color(0xFF1E88E5),
  'Moradia': Color(0xFF43A047),
  'Saúde': Color(0xFF8E24AA),
  'Lazer': Color(0xFFFB8C00),
  'Educação': Color(0xFF00897B),
  'Mercado': Color(0xFFF4511E),
  'Assinaturas': Color(0xFF3949AB),
  'Outros': Color(0xFF757575),
};

/// Aba "Resumo" do home: gastos do mês (real + previsto) e próximos vencimentos.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _atualizar(WidgetRef ref) async {
    await ref.read(lancamentosRepositoryProvider).ensureVigenteCopies();
    ref.invalidate(lancamentosStreamProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumo = ref.watch(resumoMesProvider);
    final porCategoria = ref.watch(gastosPorCategoriaMesProvider);
    final proximos = ref.watch(proximosVencimentosProvider);

    return RefreshIndicator(
      onRefresh: () => _atualizar(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const _SeletorMesHeader(),
          const SizedBox(height: 12),
          _CardGastosMes(resumo: resumo),
          const SizedBox(height: 16),
          const _CardAnaliseIA(),
          const SizedBox(height: 16),
          _PatrimonioSection(
            patrimonioCents: ref.watch(patrimonioTotalProvider),
            rendimentoCents: ref.watch(rendimentoAcumuladoProvider),
          ),
          const SizedBox(height: 16),
          Text('Por categoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          _DonutGastosCategoria(
            gastos: porCategoria,
            totalCents: resumo.saidasCents,
          ),
          const SizedBox(height: 16),
          _MetasSection(metas: ref.watch(metasComProgressoProvider)),
          const SizedBox(height: 16),
          Text('Próximos vencimentos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          if (proximos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nenhum vencimento próximo.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            for (final l in proximos.take(5))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l.descricao),
                subtitle: Text('Vence ${formatoData(l.vencimento!)}'),
                trailing: Text(
                  formatoBRL(l.valorCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (proximos.length > 5)
              TextButton(
                onPressed: () => context.push(AppRoutes.proximosVencimentos),
                child: Text('Ver todos (${proximos.length})'),
              ),
          ],
        ],
      ),
    );
  }
}

class _CardGastosMes extends StatelessWidget {
  const _CardGastosMes({required this.resumo});

  final ResumoMes resumo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo do mês', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              formatoBRL(resumo.saldoCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: resumo.saldoCents >= 0
                    ? Colors.green.shade700
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ValorRotulado(
                    rotulo: 'Entradas',
                    valor: resumo.entradasCents,
                    cor: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ValorRotulado(
                    rotulo: 'Saídas',
                    valor: resumo.saidasCents,
                    cor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Previsto no mês: ${formatoBRL(resumo.previstoCents)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValorRotulado extends StatelessWidget {
  const _ValorRotulado({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final int valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          formatoBRL(valor),
          style: theme.textTheme.titleMedium?.copyWith(
            color: cor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PatrimonioSection extends StatelessWidget {
  const _PatrimonioSection({
    required this.patrimonioCents,
    required this.rendimentoCents,
  });

  final int patrimonioCents;
  final int rendimentoCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positivo = rendimentoCents >= 0;
    final corRendimento =
        positivo ? Colors.green.shade700 : theme.colorScheme.error;

    final temInvestimentos = patrimonioCents != 0 || rendimentoCents != 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Patrimônio',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.investimentos),
                  child: Text(temInvestimentos ? 'Ver' : 'Gerenciar'),
                ),
              ],
            ),
            if (!temInvestimentos) ...[
              const SizedBox(height: 4),
              Text(
                'Nenhum investimento cadastrado.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                formatoBRL(patrimonioCents),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
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
                    '${formatoBRL(rendimentoCents.abs())} rendimento',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: corRendimento,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DonutGastosCategoria extends StatelessWidget {
  const _DonutGastosCategoria({
    required this.gastos,
    required this.totalCents,
  });

  final List<GastoCategoria> gastos;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (gastos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sem gastos neste mês.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final total = totalCents > 0 ? totalCents.toDouble() : 1.0;
    final sections = [
      for (final g in gastos)
        PieChartSectionData(
          value: g.valorCents.toDouble(),
          color: _coresCategorias[g.categoria] ?? theme.colorScheme.primary,
          radius: 42,
          showTitle: false,
        ),
    ];

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 46,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final g in gastos)
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _coresCategorias[g.categoria] ??
                      theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(g.categoria)),
              Text(
                formatoBRL(g.valorCents),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${(g.valorCents / total * 100).toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}

class _MetasSection extends ConsumerWidget {
  const _MetasSection({required this.metas});

  final List<MetaComProgresso> metas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (metas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Nenhuma meta definida.')),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.metas),
                    child: const Text('Criar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Metas', style: theme.textTheme.titleMedium)),
            TextButton(
              onPressed: () => context.push(AppRoutes.metas),
              child: const Text('Gerenciar'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final m in metas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MetaProgressoTile(meta: m),
          ),
      ],
    );
  }
}

class _MetaProgressoTile extends StatelessWidget {
  const _MetaProgressoTile({required this.meta});

  final MetaComProgresso meta;

  Color _corProgresso(ColorScheme scheme) {
    if (meta.estourou) return scheme.error;
    if (meta.quaseEstourada) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = _corProgresso(theme.colorScheme);
    final pct = meta.percentual;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta.meta.categoria,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${formatoBRL(meta.gastoCents)} de '
                  '${formatoBRL(meta.meta.valorLimiteCents)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct.clamp(0, 100)) / 100,
                minHeight: 8,
                color: cor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pct%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorMesHeader extends ConsumerWidget {
  const _SeletorMesHeader();

  static const _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mesAno = ref.watch(mesSelecionadoProvider);
    final nomeCapitalizado = '${_meses[mesAno.month - 1]} ${mesAno.year}';

    final agora = DateTime.now();
    final ehMesAtual =
        mesAno.year == agora.year && mesAno.month == agora.month;

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(mesSelecionadoProvider.notifier).mesAnterior();
              },
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  context.push(AppRoutes.historicoMeses);
                },
                child: Column(
                  children: [
                    Text(
                      nomeCapitalizado,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!ehMesAtual)
                      Text(
                        'Histórico de Meses',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(mesSelecionadoProvider.notifier).proximoMes();
              },
            ),
            if (!ehMesAtual)
              IconButton(
                tooltip: 'Voltar ao mês atual',
                icon: const Icon(Icons.today),
                onPressed: () {
                  ref.read(mesSelecionadoProvider.notifier).resetarParaAtual();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CardAnaliseIA extends ConsumerStatefulWidget {
  const _CardAnaliseIA();

  @override
  ConsumerState<_CardAnaliseIA> createState() => _CardAnaliseIAState();
}

class _CardAnaliseIAState extends ConsumerState<_CardAnaliseIA> {
  bool _carregando = false;
  String? _analiseTexto;
  String? _erro;

  Future<void> _gerarAnalise() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resumo = ref.read(resumoMesProvider);
    final gastos = ref.read(gastosPorCategoriaMesProvider);
    final mesAno = ref.read(mesSelecionadoProvider);
    final formatMes = DateFormat('MMMM yyyy', 'pt_BR').format(mesAno);

    try {
      final repo = ref.read(ditadoRepositoryProvider);
      final texto = await repo.gerarAnaliseMensal(resumo, gastos, formatMes);
      if (mounted) {
        setState(() {
          _analiseTexto = texto;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível gerar a análise no momento. Tente novamente.';
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Análise Inteligente (IA)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_analiseTexto != null || _erro != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _gerarAnalise,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_analiseTexto == null && !_carregando && _erro == null) ...[
              Text(
                'Receba um diagnóstico completo dos seus gastos e dicas de economia geradas por Inteligência Artificial para este mês.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _gerarAnalise,
                icon: const Icon(Icons.psychology_outlined),
                label: const Text('Gerar Diagnóstico por IA'),
              ),
            ] else if (_carregando) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('A IA está analisando seu orçamento...'),
                  ),
                ],
              ),
            ] else if (_analiseTexto != null) ...[
              Text(
                _analiseTexto!,
                style: theme.textTheme.bodyMedium,
              ),
            ] else if (_erro != null) ...[
              Text(
                _erro!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}