import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/rendimento_investimento.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_movimentos_investimento_repository.dart';
import '../../../support/fake_rendimentos_investimento_repository.dart';

Future<void> _aguardarInvestimentos(ProviderContainer c) {
  final completer = Completer<void>();
  c.listen(investimentosStreamProvider, (_, next) {
    if (next.value != null && !completer.isCompleted) {
      completer.complete();
    }
  });
  return completer.future;
}

Future<void> _aguardarRendimentos(ProviderContainer c) {
  final completer = Completer<void>();
  c.listen(rendimentosStreamProvider, (_, next) {
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

  test('resumo de rendimentos: totais, ranking, maior ganho e maior perda',
      () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'cdb',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 11000,
        valorInvestidoCents: 10000,
      ),
      const Investimento(
        id: 'acao',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3000,
        valorInvestidoCents: 40000,
      ),
      const Investimento(
        id: 'lci',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'LCI',
        saldoCents: 50500,
        valorInvestidoCents: 50000,
      ),
      const Investimento(
        id: 'sem',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'Fundo',
        saldoCents: 99999,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [investimentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    final resumo = container.read(resumoRendimentosProvider);

    // Aplicado 100000; atual 11000 + 30000 + 50500 = 91500.
    expect(resumo.investidoCents, 100000);
    expect(resumo.atualCents, 91500);
    expect(resumo.rendimentoCents, -8500);
    expect(resumo.rentabilidadePercent, closeTo(-8.5, 0.001));
    expect(resumo.semValorInvestido, 1);
    expect(resumo.ranking.map((i) => i.id), ['cdb', 'lci', 'acao']);
    expect(resumo.maiorGanho?.id, 'cdb');
    expect(resumo.maiorPerda?.id, 'acao');
    expect(container.read(rendimentoAcumuladoProvider), -8500);
  });

  test('sem perdas, maiorPerda é null', () {
    final resumo = ResumoRendimentos.de(const [
      Investimento(
        id: 'a',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'A',
        saldoCents: 200,
        valorInvestidoCents: 100,
      ),
    ]);
    expect(resumo.maiorGanho?.id, 'a');
    expect(resumo.maiorPerda, isNull);
  });

  test('rendimentosPorAtivoProvider filtra por investimento', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
      const Investimento(
        id: 'i2',
        classe: TipoClasseInvestimento.fii,
        nome: 'XPML11',
        quantidade: 5,
        precoAtualCents: 10000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository([
      RendimentoInvestimento(
        id: 'r1',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 5000,
        data: DateTime(2026, 8, 15),
      ),
      RendimentoInvestimento(
        id: 'r2',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.juros,
        valorCents: 3000,
        data: DateTime(2026, 7, 10),
      ),
      RendimentoInvestimento(
        id: 'r3',
        investimentoId: 'i2',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 2000,
        data: DateTime(2026, 8, 20),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
        rendimentosInvestimentoRepositoryProvider
            .overrideWithValue(rendimentos),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    await _aguardarRendimentos(container);

    final i1Rendimentos = container.read(rendimentosPorAtivoProvider('i1'));
    final i2Rendimentos = container.read(rendimentosPorAtivoProvider('i2'));

    expect(i1Rendimentos.length, 2);
    expect(i2Rendimentos.length, 1);
    expect(i1Rendimentos[0].tipo, TipoRendimentoInvestimento.dividendo);
    expect(i2Rendimentos.single.valorCents, 2000);
  });

  test('rendimentosPorMesProvider agrupa por mês ordenado desc', () async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository([
      // Agosto 2026
      RendimentoInvestimento(
        id: 'r1',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 5000,
        data: DateTime(2026, 8, 15),
      ),
      RendimentoInvestimento(
        id: 'r2',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.juros,
        valorCents: 3000,
        data: DateTime(2026, 8, 10),
      ),
      // Julho 2026
      RendimentoInvestimento(
        id: 'r3',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 2000,
        data: DateTime(2026, 7, 20),
      ),
      // Setembro 2026 (mais recente)
      RendimentoInvestimento(
        id: 'r4',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 7000,
        data: DateTime(2026, 9, 5),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
        rendimentosInvestimentoRepositoryProvider
            .overrideWithValue(rendimentos),
      ],
    );
    addTearDown(container.dispose);

    await _aguardarInvestimentos(container);
    await _aguardarRendimentos(container);

    final meses = container.read(rendimentosPorMesProvider);

    // Ordem: Setembro, Agosto, Julho (mais recente primeiro)
    expect(meses.length, 3);
    expect(meses[0].ano, 2026);
    expect(meses[0].mes, 9);
    expect(meses[0].totalCents, 7000);
    expect(meses[0].rendimentos.length, 1);

    expect(meses[1].ano, 2026);
    expect(meses[1].mes, 8);
    expect(meses[1].totalCents, 8000); // 5000 + 3000
    expect(meses[1].rendimentos.length, 2);

    expect(meses[2].ano, 2026);
    expect(meses[2].mes, 7);
    expect(meses[2].totalCents, 2000);
  });
}
