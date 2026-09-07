import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
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
          _CardGastosMes(resumo: resumo),
          const SizedBox(height: 16),
          Text('Por categoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          _DonutGastosCategoria(
            gastos: porCategoria,
            totalCents: resumo.realCents,
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
            Text('Gastos do mês', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              formatoBRL(resumo.realCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
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