import '../../../theme/caderneta.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/icones.dart';
import '../../cartoes/application/cartoes_providers.dart';
import '../../cartoes/domain/formas_pagamento.dart';
import '../../cartoes/presentation/cartoes_screen.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../../open_finance/application/open_finance_providers.dart';
import '../../open_finance/domain/fatura_cartao.dart';
import '../application/dashboard_providers.dart';

/// "Fatura fechada · vence 12/10" ou "Fatura aberta (até hoje) · vence 12/11".
String textoFatura(FaturaDoMes f) {
  final dia = f.vencimento.day.toString().padLeft(2, '0');
  final mes = f.vencimento.month.toString().padLeft(2, '0');
  return '${f.aberta ? 'Fatura aberta (até hoje)' : 'Fatura fechada'}'
      ' · vence $dia/$mes';
}

class RelatorioCartoesWidget extends ConsumerWidget {
  const RelatorioCartoesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lancamentos = ref.watch(lancamentosContabeisProvider);
    final mesAno = ref.watch(mesSelecionadoProvider);
    final cartoes = ref.watch(cartoesControllerProvider).value ?? const [];
    final contas = ref.watch(contasConectadasProvider).value ?? const [];
    final paleta = Caderneta.paletaCategorias(theme.brightness);

    // Cartões do Open Finance: a fatura que vence no mês.
    final faturas = faturasDoMes(
      cartoes: [for (final c in contas) ...c.cartoes],
      lancamentos: lancamentos,
      mes: mesAno,
      agora: DateTime.now(),
    );
    // Só o mês selecionado no painel; estorno de cartão abate o cartão.
    final despesas = lancamentos.where(
      (l) =>
          l.valorDespesaCents != 0 &&
          l.data.year == mesAno.year &&
          l.data.month == mesAno.month,
    );
    final grupos =
        agruparPorFormaPagamento(despesas, cartoes, faturas: faturas);
    final totalGasto = grupos.fold<int>(0, (s, g) => s + g.totalCents);
    final temFatura = grupos.any((g) => g.fatura != null);

    // Cor fixa por grupo: Pix e débito, cor do cartão cadastrado, ou uma cor
    // da paleta para cartões não cadastrados e outras formas.
    var proximaCor = 0;
    final cores = <GrupoFormaPagamento, Color>{
      for (final g in grupos)
        g: switch (g) {
          GrupoFormaPagamento(tipo: TipoGrupoForma.conta) => paleta[4],
          GrupoFormaPagamento(:final cartao?) =>
            _corDoCartao(cartao.corHex) ?? theme.colorScheme.primary,
          _ => paleta[(proximaCor++ * 2 + 1) % paleta.length],
        },
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(Icones.distribuicao,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Despesas por forma de pagamento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalGasto == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma despesa cadastrada neste mês.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (final g in grupos)
                        PieChartSectionData(
                          color: cores[g],
                          value: g.totalCents.toDouble(),
                          title:
                              '${((g.totalCents / totalGasto) * 100).toStringAsFixed(0)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              for (final g in grupos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cores[g],
                    radius: 12,
                    child: PhosphorIcon(
                      g.tipo == TipoGrupoForma.conta
                          ? Icones.pix
                          : Icones.cartao,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(g.titulo),
                  subtitle: _subtitulo(g),
                  onTap: g.nomeNaoCadastrado == null
                      ? null
                      : () => abrirFormularioCartao(
                            context,
                            nomeSugerido: g.nomeNaoCadastrado,
                          ),
                  trailing: Text(
                    formatoBRL(g.totalCents),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (temFatura) ...[
                const SizedBox(height: 8),
                Text(
                  'Cartões conectados: valor da fatura que vence neste mês, '
                  'informado pelo banco (Open Finance).',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static Widget? _subtitulo(GrupoFormaPagamento g) {
    final fatura = g.fatura;
    if (fatura != null) return Text(textoFatura(fatura));
    final cartao = g.cartao;
    if (cartao != null) {
      return Text(
        'Fecha dia ${cartao.diaFechamento} | Vence dia ${cartao.diaVencimento}',
      );
    }
    if (g.nomeNaoCadastrado != null) {
      return const Text('Toque para cadastrar este cartão');
    }
    return null;
  }

  static Color? _corDoCartao(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}
