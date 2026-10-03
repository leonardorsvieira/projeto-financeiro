import '../../../theme/caderneta.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../core/edge_function.dart';
import '../../../core/texto_ia.dart';
import '../../../theme/icones.dart';
import '../../acesso/presentation/aviso_vencimento_acesso.dart';
import '../../auth/application/auth_controller.dart';
import '../../ditado/application/ditado_providers.dart';
import '../../ditado/domain/ditado_repository.dart';
import '../../home/domain/app_routes.dart';
import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../../metas/application/metas_providers.dart';
import '../../open_finance/application/open_finance_providers.dart';
import '../../open_finance/domain/saldo_nas_contas.dart';
import '../application/dados_analise_mes.dart';
import '../application/dashboard_providers.dart';
import '../application/home_widget_service.dart';
import '../application/saudacao.dart';
import '../application/widget_agenda.dart';
import 'relatorio_cartoes_widget.dart';
/// Cor do donut por categoria (ordem fixa; categorias novas usam a ultima).
const _ordemCategorias = <String>[
  'Alimentação',
  'Transporte',
  'Moradia',
  'Saúde',
  'Lazer',
  'Educação',
  'Mercado',
  'Assinaturas',
  'Outros',
];

Color corDaCategoria(String categoria, Brightness b) {
  final paleta = Caderneta.paletaCategorias(b);
  final i = _ordemCategorias.indexOf(categoria);
  return i < 0 ? Caderneta.corExtra(categoria, b) : paleta[i];
}

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
    final saldoContas = ref.watch(saldoNasContasProvider);

    HomeWidgetService.atualizarWidget(
      saldoFormatado: formatoBRL(resumo.saldoCents),
      vencimentos: linhasAgendaWidget(proximos),
    );

    return RefreshIndicator(
      onRefresh: () => _atualizar(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const AvisoVencimentoAcesso(),
          _Saudacao(nome: ref.watch(primeiroNomeUsuarioProvider)),
          const SizedBox(height: 12),
          // Não depende do mês: fica antes do seletor.
          if (saldoContas != null) ...[
            _CardSaldoContas(saldo: saldoContas),
            const SizedBox(height: 12),
          ],
          const _SeletorMesHeader(),
          const SizedBox(height: 12),
          _CardGastosMes(resumo: resumo),
          const SizedBox(height: 16),
          const RelatorioCartoesWidget(),
          const SizedBox(height: 16),
          // Chave pelo mês: ao trocar de mês, a análise anterior some.
          _CardAnaliseIA(key: ValueKey(ref.watch(mesSelecionadoProvider))),
          const SizedBox(height: 16),
          const _CardGuiaInvestimentos(),
          const SizedBox(height: 16),
          _PatrimonioSection(
            patrimonioCents: ref.watch(patrimonioTotalProvider),
            resumo: ref.watch(resumoRendimentosProvider),
          ),
          const SizedBox(height: 16),
          Text('Despesas por categoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          _DonutGastosCategoria(
            gastos: porCategoria,
            // Soma do que aparece (estorno pode zerar uma categoria).
            totalCents: porCategoria.fold(0, (s, g) => s + g.valorCents),
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
                leading: const PhosphorIcon(Icones.vencimento),
                title: Text(l.descricao),
                subtitle: Text(_textoVencimento(l.vencimento!)),
                trailing: Text(
                  formatoBRL(l.valorCents),
                  style: CadernetaTexto.numero(size: 16).copyWith(
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

class _Saudacao extends StatelessWidget {
  const _Saudacao({this.nome});

  final String? nome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agora = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(saudacaoPara(agora, nome), style: theme.textTheme.headlineSmall),
        Text(dataPorExtenso(agora), style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

String _textoVencimento(DateTime vencimento) {
  final hoje = DateTime.now();
  final dias = DateTime(vencimento.year, vencimento.month, vencimento.day)
      .difference(DateTime(hoje.year, hoje.month, hoje.day))
      .inDays;
  if (dias < 0) return 'Venceu em ${formatoData(vencimento)}';
  if (dias == 0) return 'Vence hoje';
  if (dias == 1) return 'Vence amanhã';
  return 'Vence em $dias dias';
}

/// "Atualizado hoje às 14:32", "Atualizado ontem às 09:10" ou
/// "Atualizado em 28/09 às 09:10".
String textoAtualizacaoSaldo(DateTime atualizado, DateTime agora) {
  final dias = DateTime(agora.year, agora.month, agora.day)
      .difference(DateTime(atualizado.year, atualizado.month, atualizado.day))
      .inDays;
  final hora = DateFormat('HH:mm').format(atualizado);
  if (dias <= 0) return 'Atualizado hoje às $hora';
  if (dias == 1) return 'Atualizado ontem às $hora';
  return 'Atualizado em ${DateFormat('dd/MM').format(atualizado)} às $hora';
}

/// Saldo real das contas nos bancos conectados (última sincronização).
class _CardSaldoContas extends StatelessWidget {
  const _CardSaldoContas({required this.saldo});

  final SaldoNasContas saldo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = saldo.totalCents;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.openFinance),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PhosphorIcon(Icones.banco, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saldo nas contas',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const PhosphorIcon(Icones.proximo, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatoBRL(total),
                style: CadernetaTexto.numero(size: 28).copyWith(
                  color: total < 0 ? theme.colorScheme.error : null,
                ),
              ),
              if (saldo.porBanco.length > 1) ...[
                const SizedBox(height: 8),
                for (final b in saldo.porBanco)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.nomeBanco,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatoBRL(b.saldoCents),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                b.saldoCents < 0 ? theme.colorScheme.error : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                textoAtualizacaoSaldo(saldo.atualizadoEm, DateTime.now()),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
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
    return PapelPautado(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo do mês', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              formatoBRL(resumo.saldoCents),
              style: CadernetaTexto.numero(size: 34).copyWith(
                color: resumo.saldoCents >= 0
                    ? Caderneta.corReceita(context)
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ValorRotulado(
                    rotulo: 'Receitas',
                    valor: resumo.entradasCents,
                    cor: Caderneta.corReceita(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ValorRotulado(
                    rotulo: 'Despesas',
                    valor: resumo.saidasCents,
                    cor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            // Não é renda nem gasto, mas mexe no saldo como no extrato.
            if (resumo.resgatesCents > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Resgatado de investimentos: '
                '+${formatoBRL(resumo.resgatesCents)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Caderneta.corReceita(context),
                ),
              ),
            ],
            if (resumo.aplicacoesCents > 0) ...[
              SizedBox(height: resumo.resgatesCents > 0 ? 4 : 12),
              Text(
                'Aplicado em investimentos: '
                '-${formatoBRL(resumo.aplicacoesCents)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Previsto no mês: ${formatoBRL(resumo.previstoCents)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
          style: CadernetaTexto.numero(size: 16).copyWith(
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
    required this.resumo,
  });

  final int patrimonioCents;
  final ResumoRendimentos resumo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rendimentoCents = resumo.rendimentoCents;
    final positivo = rendimentoCents >= 0;
    final corRendimento = positivo
        ? Caderneta.corReceita(context)
        : theme.colorScheme.error;
    final pct = resumo.rentabilidadePercent;

    final temInvestimentos = patrimonioCents != 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Patrimônio', style: theme.textTheme.titleMedium),
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
              // Só há rendimento quando o banco informou o valor aplicado.
              if (resumo.ranking.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    PhosphorIcon(
                      positivo ? Icones.sobe : Icones.desce,
                      color: corRendimento,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${positivo ? '+' : '-'}'
                      '${formatoBRL(rendimentoCents.abs())}'
                      '${pct == null ? '' : ' (${pct.toStringAsFixed(1).replaceAll('.', ',')}%)'}'
                      ' ${positivo ? 'rendimento' : 'de perda'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: corRendimento,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DonutGastosCategoria extends StatelessWidget {
  const _DonutGastosCategoria({required this.gastos, required this.totalCents});

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
          color: corDaCategoria(g.categoria, theme.brightness),
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
                  color:
                      corDaCategoria(g.categoria, theme.brightness),
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

  Color _corProgresso(BuildContext context, ColorScheme scheme) {
    if (meta.estourou) return scheme.error;
    if (meta.quaseEstourada) return Caderneta.ocre(context);
    return Caderneta.corReceita(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = _corProgresso(context, theme.colorScheme);
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
                    'Orçamento · ${meta.meta.categoria}',
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
                textoUtilizacaoOrcamento(meta),
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

/// "83% utilizado. Restam R$ 260,00 até o fim do mês." ou, se excedido,
/// "Orçamento excedido em R$ X.".
String textoUtilizacaoOrcamento(MetaComProgresso m) {
  final diferenca = m.meta.valorLimiteCents - m.gastoCents;
  if (diferenca < 0) {
    return 'Orçamento excedido em ${formatoBRL(-diferenca)}.';
  }
  return '${m.percentual}% utilizado. '
      'Restam ${formatoBRL(diferenca)} até o fim do mês.';
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
    'Dezembro',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mesAno = ref.watch(mesSelecionadoProvider);
    final nomeCapitalizado = '${_meses[mesAno.month - 1]} ${mesAno.year}';

    final agora = DateTime.now();
    final ehMesAtual = mesAno.year == agora.year && mesAno.month == agora.month;

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              icon: const PhosphorIcon(Icones.anterior),
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
                        'Histórico de meses',
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
              icon: const PhosphorIcon(Icones.proximo),
              onPressed: () {
                ref.read(mesSelecionadoProvider.notifier).proximoMes();
              },
            ),
            if (!ehMesAtual)
              IconButton(
                tooltip: 'Voltar ao mês atual',
                icon: const PhosphorIcon(Icones.hoje),
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

/// Entrada do Guia de investimentos (IA).
class _CardGuiaInvestimentos extends StatelessWidget {
  const _CardGuiaInvestimentos();

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
                PhosphorIcon(Icones.rendimento, color: Caderneta.ocre(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guia de investimentos (IA)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Um plano para investir melhor: seus números, o mercado de hoje '
              'e as lições dos livros de investimento mais lidos.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.guiaInvestimentos),
              icon: const PhosphorIcon(Icones.ia),
              label: const Text('Abrir meu guia'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Análise por IA do mês selecionado (só os números desse mês). O widget é
/// recriado a cada mês (chave no [DashboardScreen]).
class _CardAnaliseIA extends ConsumerStatefulWidget {
  const _CardAnaliseIA({super.key});

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
    final dados = dadosAnaliseDoMes(
      resumo: resumo,
      gastos: gastos,
      mes: mesAno,
      hoje: DateTime.now(),
    );

    try {
      final repo = ref.read(ditadoRepositoryProvider);
      final texto = await repo.gerarAnaliseMensal(dados, mesPorExtenso(mesAno));
      if (mounted) {
        setState(() {
          _analiseTexto = texto;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e is DitadoException && e.mensagem == mensagemAcessoInativo
              ? e.mensagem
              : 'Não foi possível gerar a análise no momento. Tente novamente.';
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mesAno = ref.watch(mesSelecionadoProvider);
    final semLancamentos = mesSemLancamentos(
      ref.watch(resumoMesProvider),
      ref.watch(gastosPorCategoriaMesProvider),
    );
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(Icones.ia, color: Caderneta.ocre(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análise do mês (IA)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mesPorExtenso(mesAno),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if ((_analiseTexto != null || _erro != null) && !semLancamentos)
                  IconButton(
                    tooltip: 'Gerar de novo',
                    icon: const PhosphorIcon(Icones.atualizar, size: 20),
                    onPressed: _gerarAnalise,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (semLancamentos && !_carregando) ...[
              Text(
                'Não há lançamentos em ${mesPorExtenso(mesAno)} para analisar.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else if (_analiseTexto == null && !_carregando && _erro == null) ...[
              Text(
                'Receba um diagnóstico dos gastos de ${mesPorExtenso(mesAno)} '
                'e dicas de economia geradas por Inteligência Artificial, '
                'só com os números deste mês.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _gerarAnalise,
                icon: const PhosphorIcon(Icones.analisar),
                label: const Text('Gerar análise por IA'),
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
                    child: Text('Analisando seu orçamento…'),
                  ),
                ],
              ),
            ] else if (_analiseTexto != null) ...[
              TextoIA(_analiseTexto!),
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
