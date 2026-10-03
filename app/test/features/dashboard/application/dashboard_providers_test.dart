import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/dashboard/application/dashboard_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';

import '../../../support/fake_lancamentos_repository.dart';

Lancamento _lanc({
  required String id,
  required int valorCents,
  required DateTime data,
  DateTime? vencimento,
  TipoLancamento tipo = TipoLancamento.despesa,
  String categoria = 'Outros',
}) {
  final agora = DateTime.now();
  return Lancamento(
    id: id,
    descricao: id,
    categoria: categoria,
    valorCents: valorCents,
    formaPagamento: 'Pix',
    data: data,
    vencimento: vencimento,
    tipo: tipo,
    createdAt: agora,
    updatedAt: agora,
  );
}

void main() {
  Future<void> aguardarEmissao(ProviderContainer c) {
    final completer = Completer<void>();
    late final ProviderSubscription sub;
    sub = c.listen(lancamentosStreamProvider, (_, next) {
      final data = (next as AsyncValue<List<Lancamento>>).value;
      if (data != null && !completer.isCompleted) {
        completer.complete();
        sub.close();
      }
    });
    return completer.future;
  }

  test('resumoMesProvider soma real do mês e previstos sem duplicar', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      // Real deste mês: soma.
      _lanc(id: '1', valorCents: 10000, data: mes.add(const Duration(days: 3))),
      // Previsto deste mês: vence este mês, data fora deste mês.
      _lanc(
        id: '2',
        valorCents: 5000,
        data: outroMes,
        vencimento: mes.add(const Duration(days: 10)),
      ),
      // Vence este mês MAS data também neste mês → conta como real, não previsto.
      _lanc(
        id: '3',
        valorCents: 2000,
        data: mes.add(const Duration(days: 1)),
        vencimento: mes.add(const Duration(days: 15)),
      ),
      // Fora do mês atual: ignora.
      _lanc(id: '4', valorCents: 99999, data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final resumo = container.read(resumoMesProvider);

    expect(resumo.realCents, 12000, reason: '1 + 3 com data no mês');
    expect(resumo.previstoCents, 5000, reason: 'somente lançamento 2');
    expect(resumo.totalCents, 17000);
  });

  test('resumoMesProvider zera quando nada no mês atual', () async {
    final agora = DateTime.now();
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      _lanc(id: '1', valorCents: 99999, data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final resumo = container.read(resumoMesProvider);

    expect(resumo.realCents, 0);
    expect(resumo.previstoCents, 0);
  });

  test('resumoMesProvider separa entradas, saídas e previsto de despesa',
      () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      // Receita do mês → entradas.
      _lanc(
        id: 'r1',
        valorCents: 300000,
        data: mes.add(const Duration(days: 2)),
        tipo: TipoLancamento.receita,
      ),
      // Despesa do mês → saídas.
      _lanc(id: 'd1', valorCents: 10000, data: mes.add(const Duration(days: 3))),
      // Receita fora do mês → ignora.
      _lanc(
        id: 'r2',
        valorCents: 50000,
        data: outroMes,
        tipo: TipoLancamento.receita,
      ),
      // Receita com vencimento no mês NÃO gera previsto.
      _lanc(
        id: 'r3',
        valorCents: 100000,
        data: outroMes,
        vencimento: mes.add(const Duration(days: 10)),
        tipo: TipoLancamento.receita,
      ),
      // Despesa que vence no mês com data fora → previsto.
      _lanc(
        id: 'd2',
        valorCents: 5000,
        data: outroMes,
        vencimento: mes.add(const Duration(days: 10)),
      ),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final resumo = container.read(resumoMesProvider);

    expect(resumo.entradasCents, 300000);
    expect(resumo.saidasCents, 10000);
    expect(resumo.realCents, resumo.saidasCents, reason: 'alias compat');
    expect(resumo.previstoCents, 5000, reason: 'só despesa');
    expect(resumo.saldoCents, 290000);
    expect(resumo.totalCents, 15000, reason: 'saídas + previsto');
  });

  group('investimentos no saldo do mês (como no extrato)', () {
    final mes = DateTime(2026, 9);
    final lancamentos = [
      _lanc(
        id: 'salario',
        valorCents: 500000,
        data: DateTime(2026, 9, 5),
        tipo: TipoLancamento.receita,
      ),
      _lanc(id: 'mercado', valorCents: 120000, data: DateTime(2026, 9, 6)),
      // Resgatou da caixinha: entra no saldo.
      _lanc(
        id: 'resgate',
        valorCents: 80000,
        data: DateTime(2026, 9, 7),
        tipo: TipoLancamento.receita,
        categoria: categoriaMovimentacaoInvestimento,
      ),
      // Aplicou no CDB: sai do saldo.
      _lanc(
        id: 'aplicacao',
        valorCents: 300000,
        data: DateTime(2026, 9, 8),
        categoria: categoriaMovimentacaoInvestimento,
      ),
      // Aplicação com vencimento no mês, mas data fora: nunca é previsto.
      _lanc(
        id: 'aplicacao-agosto',
        valorCents: 7000,
        data: DateTime(2026, 8, 30),
        vencimento: DateTime(2026, 9, 10),
        categoria: categoriaMovimentacaoInvestimento,
      ),
      // Transferência entre contas próprias continua fora de tudo.
      _lanc(
        id: 'transf',
        valorCents: 99999,
        data: DateTime(2026, 9, 9),
        tipo: TipoLancamento.receita,
        categoria: categoriaTransferenciaEntreContas,
      ),
    ];

    test('resgate soma, aplicação subtrai; receitas/despesas inalteradas', () {
      final r = resumoDoMes(lancamentos, mes);

      expect(r.entradasCents, 500000, reason: 'resgate não é renda');
      expect(r.saidasCents, 120000, reason: 'aplicação não é gasto');
      expect(r.previstoCents, 0);
      expect(r.resgatesCents, 80000);
      expect(r.aplicacoesCents, 300000);
      expect(r.investimentosLiquidoCents, -220000);
      // 5000 − 1200 + 800 − 3000 = 1600
      expect(r.saldoCents, 160000);
    });

    test('toString (análise por IA) inclui investimentos e saldo', () {
      final texto = resumoDoMes(lancamentos, mes).toString();
      expect(texto, contains('resgates de investimento: 80000'));
      expect(texto, contains('aplicações em investimento: 300000'));
      expect(texto, contains('saldo: 160000'));
    });

    test('resumoMesProvider e histórico usam a mesma regra', () async {
      final agora = DateTime.now();
      final noMes = DateTime(agora.year, agora.month, 1);
      final repo = FakeLancamentosRepository([
        _lanc(
          id: 'resgate',
          valorCents: 10000,
          data: noMes,
          tipo: TipoLancamento.receita,
          categoria: categoriaMovimentacaoInvestimento,
        ),
        _lanc(id: 'gasto', valorCents: 4000, data: noMes),
      ]);
      final container = ProviderContainer(
        overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await aguardarEmissao(container);

      expect(container.read(resumoMesProvider).saldoCents, 6000);
      expect(
        container.read(historicoUltimosMesesProvider).first.resumo.saldoCents,
        6000,
      );
      // Donut continua só com gastos de verdade.
      expect(container.read(gastosPorCategoriaMesProvider).single.valorCents,
          4000);
    });
  });

  test('gastosPorCategoriaMesProvider ignora receitas no donut', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final repo = FakeLancamentosRepository([
      _lanc(
        id: 'r1',
        valorCents: 300000,
        data: mes.add(const Duration(days: 1)),
        tipo: TipoLancamento.receita,
      ),
      _lanc(id: 'd1', valorCents: 10000, data: mes.add(const Duration(days: 2))),
      _lanc(id: 'd2', valorCents: 20000, data: mes.add(const Duration(days: 3))),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final porCategoria = container.read(gastosPorCategoriaMesProvider);

    expect(porCategoria.single.valorCents, 30000);
  });
}