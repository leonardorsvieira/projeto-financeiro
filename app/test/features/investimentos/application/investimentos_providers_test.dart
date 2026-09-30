import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';

import '../../../support/fake_investimentos_repository.dart';

Future<void> _aguardarInvestimentos(ProviderContainer c) {
  final completer = Completer<void>();
  c.listen(investimentosStreamProvider, (_, next) {
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
}
