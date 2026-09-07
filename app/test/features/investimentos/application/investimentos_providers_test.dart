import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/movimento_investimento.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_movimentos_investimento_repository.dart';

Future<void> _aguardarInvestimentos(ProviderContainer c) {
  final completer = Completer<void>();
  c.listen(investimentosStreamProvider, (_, next) {
    if (next.value != null && !completer.isCompleted) {
      completer.complete();
    }
  });
  return completer.future;
}

Future<void> _aguardarMovimentos(
  ProviderContainer c,
  String id,
) {
  final completer = Completer<void>();
  c.listen(movimentosPorInvestimentoProvider(id), (_, next) {
    if (next.value != null && !completer.isCompleted) {
      completer.complete();
    }
  });
  return completer.future;
}

void main() {
  test('investimentosPorClasseProvider agrupa na ordem fixa', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
      ),
      const Investimento(
        id: 'i2',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 50000,
      ),
      const Investimento(
        id: 'i3',
        classe: TipoClasseInvestimento.fii,
        nome: 'XPML11',
        quantidade: 5,
        precoAtualCents: 10000,
      ),
      const Investimento(
        id: 'i4',
        classe: TipoClasseInvestimento.bancoDigital,
        nome: 'Nubank',
        saldoCents: 2000,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);

    final porClasse = container.read(investimentosPorClasseProvider);

    expect(porClasse.totalAtivos, 4);
    expect(
      porClasse.grupos.map((g) => g.classe).toList(),
      [
        TipoClasseInvestimento.rendaFixa,
        TipoClasseInvestimento.bancoDigital,
        TipoClasseInvestimento.acao,
        TipoClasseInvestimento.fii,
      ],
    );
    expect(porClasse.grupos[0].investimentos.single.nome, 'CDB');
    expect(porClasse.grupos[2].investimentos.single.nome, 'PETR4');
    expect(porClasse.grupos[3].investimentos.single.nome, 'XPML11');
  });

  test('investimentosPorClasseProvider ignora classes vazias', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 1,
        precoAtualCents: 1000,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    final porClasse = container.read(investimentosPorClasseProvider);

    expect(porClasse.grupos, hasLength(1));
    expect(porClasse.grupos.single.classe, TipoClasseInvestimento.acao);
    expect(porClasse.totalAtivos, 1);
  });

  test('patrimonioTotal soma qtd×preço e saldos', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
      ),
      const Investimento(
        id: 'i2',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 50000,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
      ],
    );
    addTearDown(container.dispose);
    await _aguardarInvestimentos(container);

    expect(container.read(patrimonioTotalProvider), 38500 + 50000);
  });

  test('custo e rendimento acumulado: compras e vendas', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository([
      MovimentoInvestimento(
        id: 'm1',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 5,
        precoUnitCents: 3000,
        data: DateTime(2026, 8, 1),
      ),
      MovimentoInvestimento(
        id: 'm2',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 5,
        precoUnitCents: 3000,
        data: DateTime(2026, 8, 2),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider.overrideWithValue(movimentos),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    await _aguardarMovimentos(container, 'i1');

    // Custo = 10 un × 3000 = 30000; patrimônio = 10 × 4000 = 40000.
    expect(container.read(custoPorAtivoProvider)['i1'], 30000);
    expect(container.read(custoTotalProvider), 30000);
    expect(container.read(rendimentoAcumuladoProvider), 10000);
  });

  test('venda subtrai do custo', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 5,
        precoAtualCents: 4000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository([
      MovimentoInvestimento(
        id: 'm1',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 10,
        precoUnitCents: 3000,
        data: DateTime(2026, 8, 1),
      ),
      MovimentoInvestimento(
        id: 'm2',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.venda,
        quantidade: 5,
        precoUnitCents: 3500,
        data: DateTime(2026, 8, 2),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider.overrideWithValue(movimentos),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    await _aguardarMovimentos(container, 'i1');

    // Custo = 30000 − 17500 = 12500.
    expect(container.read(custoPorAtivoProvider)['i1'], 12500);
    expect(container.read(rendimentoAcumuladoProvider), 20000 - 12500);
  });
}
