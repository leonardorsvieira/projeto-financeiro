import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/presentation/investimentos_screen.dart';

import '../../../support/fake_investimentos_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeInvestimentosRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: InvestimentosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista agrupa ativos por classe com patrimônio',
      (tester) async {
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
        classe: TipoClasseInvestimento.bancoDigital,
        nome: 'Nubank',
        saldoCents: 2500,
      ),
    ]);

    await _pump(tester, repo);

    expect(find.text('Investimentos'), findsOneWidget);
    // Títulos de classe (Renda Fixa também aparece no subtítulo do CDB)
    expect(find.text('Ações'), findsOneWidget);
    expect(find.text('Renda Fixa'), findsWidgets);
    expect(find.text('Banco Digital'), findsWidgets);
    // Ativos
    expect(find.text('PETR4'), findsOneWidget);
    expect(find.text('CDB'), findsOneWidget);
    expect(find.text('Nubank'), findsOneWidget);
    // Patrimônio
    expect(find.text('R\$ 385,00'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('R\$ 25,00'), findsOneWidget);
    // Subtitle: 10 un · R$ 38,50
    expect(find.textContaining('10 un · R\$ 38,50'), findsOneWidget);
    // Card patrimônio total
    expect(find.text('Patrimônio total'), findsOneWidget);
    expect(find.text('R\$ 910,00'), findsWidgets);
  });

  testWidgets('empty state explica que os dados vêm do Open Finance',
      (tester) async {
    await _pump(tester, FakeInvestimentosRepository());
    expect(find.text('Nenhum investimento encontrado'), findsOneWidget);
    expect(find.textContaining('Open Finance'), findsOneWidget);
  });

  testWidgets('sem cadastro, edição ou exclusão manual', (tester) async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 50000,
        pluggyId: 'p1',
      ),
    ]);
    await _pump(tester, repo);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byIcon(Icons.sync), findsNothing);
  });

  testWidgets('mostra aplicado, rendimento, destaques e ranking',
      (tester) async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'cdb',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 11000,
        valorInvestidoCents: 10000,
        pluggyId: 'p1',
      ),
      const Investimento(
        id: 'acao',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3000,
        valorInvestidoCents: 40000,
        pluggyId: 'p2',
      ),
    ]);
    await _pump(tester, repo);

    // Card: aplicado 500,00; atual 410,00; perdeu 90,00 (−18%).
    expect(find.text('Total aplicado'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('Perdeu'), findsOneWidget);
    expect(find.text('-R\$ 90,00 (-18,0%)'), findsOneWidget);
    // Destaques.
    expect(find.text('Mais rendeu'), findsOneWidget);
    expect(find.text('Mais perdeu'), findsOneWidget);
    expect(find.text('+R\$ 10,00 (+10,0%)'), findsWidgets);
    expect(find.text('-R\$ 100,00 (-25,0%)'), findsWidgets);
    expect(find.textContaining('Aplicado: R\$ 100,00'), findsOneWidget);

    // Ranking: do que mais rendeu ao que mais perdeu, numerado.
    await tester.tap(find.byTooltip('Ordenar por rendimento'));
    await tester.pumpAndSettle();
    expect(find.text('Do que mais rendeu ao que mais perdeu'), findsOneWidget);
    final cdb = tester.getTopLeft(find.text('CDB').last).dy;
    final petr = tester.getTopLeft(find.text('PETR4').last).dy;
    expect(cdb, lessThan(petr));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('sem valor aplicado avisa que não dá para calcular',
      (tester) async {
    await _pump(
      tester,
      FakeInvestimentosRepository([
        const Investimento(
          id: 'x',
          classe: TipoClasseInvestimento.rendaFixa,
          nome: 'Fundo',
          saldoCents: 1000,
          pluggyId: 'p',
        ),
      ]),
    );
    expect(find.textContaining('não informou o valor aplicado'), findsOneWidget);
    expect(find.textContaining('Aplicado: não informado'), findsOneWidget);
  });
}
