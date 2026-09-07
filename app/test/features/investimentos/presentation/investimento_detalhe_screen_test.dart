import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/movimento_investimento.dart';
import 'package:meubolso/features/investimentos/presentation/investimento_detalhe_screen.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_movimentos_investimento_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeInvestimentosRepository investimentos,
  required FakeMovimentosInvestimentoRepository movimentos,
  required String id,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(investimentos),
        movimentosInvestimentoRepositoryProvider.overrideWithValue(movimentos),
      ],
      child: MaterialApp(
        home: InvestimentoDetalheScreen(investimentoId: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const invId = 'i1';

  testWidgets('mostra posição resumida e lista de movimentos',
      (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository([
      MovimentoInvestimento(
        id: 'm1',
        investimentoId: invId,
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 10,
        precoUnitCents: 3850,
        data: DateTime(2026, 9, 1),
      ),
    ]);

    await _pump(
      tester,
      investimentos: investimentos,
      movimentos: movimentos,
      id: invId,
    );

    expect(find.text('PETR4'), findsOneWidget);
    expect(find.text('Patrimônio: R\$ 385,00'), findsOneWidget);
    expect(find.text('Movimentos'), findsOneWidget);
    expect(find.text('Compra · 10.00 un'), findsOneWidget);
    expect(find.text('R\$ 385,00'), findsOneWidget);
  });

  testWidgets('criar compra chama create e atualiza posição',
      (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository();

    await _pump(
      tester,
      investimentos: investimentos,
      movimentos: movimentos,
      id: invId,
    );

    await tester.tap(find.text('Movimento'));
    await tester.pumpAndSettle();

    // Quantidade padrão 1; preço.
    await tester.enterText(find.byType(TextField).at(0), '5');
    await tester.enterText(find.byType(TextField).at(1), '40,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(movimentos.createCount, 1);
    expect(movimentos.items.single.quantidade, 5);
    expect(movimentos.items.single.precoUnitCents, 4000);

    // Posição atualizada: 10 + 5 = 15, preço 40,00.
    final inv = investimentos.items.single;
    expect(inv.quantidade, 15);
    expect(inv.precoAtualCents, 4000);
    expect(find.text('Patrimônio: R\$ 600,00'), findsOneWidget);
  });

  testWidgets('venda maior que quantidade atual é bloqueada',
      (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository();

    await _pump(
      tester,
      investimentos: investimentos,
      movimentos: movimentos,
      id: invId,
    );

    await tester.tap(find.text('Movimento'));
    await tester.pumpAndSettle();

    // Troca para Venda.
    await tester.tap(find.text('Venda'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '40,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(movimentos.createCount, 0);
    expect(find.textContaining('A venda não pode ser maior'), findsOneWidget);
    expect(investimentos.items.single.quantidade, 10);
  });

  testWidgets('RPF: criar aporte (compra) soma saldo', (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 10000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository();

    await _pump(
      tester,
      investimentos: investimentos,
      movimentos: movimentos,
      id: invId,
    );

    await tester.tap(find.text('Movimento'));
    await tester.pumpAndSettle();

    // RF/bco: sem campo quantidade, só valor.
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '500,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(movimentos.createCount, 1);
    expect(movimentos.items.single.quantidade, 1);
    expect(movimentos.items.single.precoUnitCents, 50000);
    expect(investimentos.items.single.saldoCents, 60000);
    expect(find.text('Patrimônio: R\$ 600,00'), findsOneWidget);
  });

  testWidgets('excluir movimento pelo popup', (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3000,
      ),
    ]);
    final movimentos = FakeMovimentosInvestimentoRepository([
      MovimentoInvestimento(
        id: 'm1',
        investimentoId: invId,
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 10,
        precoUnitCents: 3000,
        data: DateTime(2026, 9, 1),
      ),
    ]);

    await _pump(
      tester,
      investimentos: investimentos,
      movimentos: movimentos,
      id: invId,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir movimento?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(movimentos.deleteCount, 1);
    expect(movimentos.items, isEmpty);
    expect(find.text('Nenhum movimento registrado.'), findsOneWidget);
  });
}
