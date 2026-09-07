import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/presentation/investimentos_screen.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_movimentos_investimento_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeInvestimentosRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(repo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
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
    // Subtitle: 10 Ações · R$ 38,50
    expect(find.text('10 Ações · R\$ 38,50'), findsOneWidget);
    // Card patrimônio total
    expect(find.text('Patrimônio total'), findsOneWidget);
    expect(find.text('R\$ 910,00'), findsWidgets);
  });

  testWidgets('empty state quando não há ativos', (tester) async {
    await _pump(tester, FakeInvestimentosRepository());
    expect(find.text('Nenhum ativo cadastrado'), findsOneWidget);
    expect(find.text('Novo ativo'), findsOneWidget);
  });

  testWidgets('criar ativo por quantidade chama repository.create',
      (tester) async {
    final repo = FakeInvestimentosRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Novo ativo'));
    await tester.pumpAndSettle();

    expect(find.text('Novo ativo'), findsWidgets);
    await tester.enterText(find.byType(TextField).at(0), 'PETR4');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.enterText(find.byType(TextField).at(2), '38,50');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.createCount, 1);
    final inv = repo.items.single;
    expect(inv.nome, 'PETR4');
    expect(inv.classe, TipoClasseInvestimento.acao);
    expect(inv.quantidade, 10);
    expect(inv.precoAtualCents, 3850);
    expect(find.text('PETR4'), findsOneWidget);
    // Aparece no card patrimônio total e no tile do ativo.
    expect(find.text('R\$ 385,00'), findsWidgets);
  });

  testWidgets('criar ativo por saldo (renda fixa) usa classe certa',
      (tester) async {
    final repo = FakeInvestimentosRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Novo ativo'));
    await tester.pumpAndSettle();

    // Seleciona Renda Fixa.
    await tester.tap(find.byType(DropdownButtonFormField<TipoClasseInvestimento>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renda Fixa').last);
    await tester.pumpAndSettle();

    expect(find.text('Saldo atual'), findsOneWidget);
    expect(find.text('Quantidade'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'CDB');
    await tester.enterText(find.byType(TextField).at(1), '500,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final inv = repo.items.single;
    expect(inv.classe, TipoClasseInvestimento.rendaFixa);
    expect(inv.saldoCents, 50000);
    expect(inv.ePorQuantidade, isFalse);
    // Aparece no card patrimônio total e no tile do ativo.
    expect(find.text('R\$ 500,00'), findsWidgets);
  });

  testWidgets('editar e excluir ativo pelo popup menu', (tester) async {
    final repo = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
      ),
    ]);
    await _pump(tester, repo);

    // Editar.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar ativo'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(2), '40,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCount, 1);
    expect(repo.items.single.precoAtualCents, 4000);
    // Aparece no card patrimônio total e no tile do ativo.
    expect(find.text('R\$ 400,00'), findsWidgets);

    // Excluir.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir ativo?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(repo.deleteCount, 1);
    expect(repo.items, isEmpty);
    expect(find.text('Nenhum ativo cadastrado'), findsOneWidget);
  });
}
