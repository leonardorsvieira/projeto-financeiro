import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/metas/application/metas_providers.dart';
import 'package:meubolso/features/metas/domain/meta.dart';
import 'package:meubolso/features/metas/presentation/metas_screen.dart';

import '../../../support/fake_lancamentos_repository.dart';
import '../../../support/fake_metas_repository.dart';

Lancamento _lanc({
  required String id,
  required int valorCents,
  required String categoria,
  required DateTime data,
}) {
  final agora = DateTime.now();
  return Lancamento(
    id: id,
    descricao: id,
    categoria: categoria,
    valorCents: valorCents,
    formaPagamento: 'Pix',
    data: data,
    vencimento: null,
    createdAt: agora,
    updatedAt: agora,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeLancamentosRepository lancamentos,
  required FakeMetasRepository metas,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lancamentosRepositoryProvider.overrideWithValue(lancamentos),
        metasRepositoryProvider.overrideWithValue(metas),
      ],
      child: const MaterialApp(home: MetasScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MetasScreen mostra lista com progresso e %, alerta e estouro',
      (tester) async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final lancamentos = FakeLancamentosRepository([
      _lanc(id: 'Pizza', valorCents: 9000, categoria: 'Alimentação', data: mes),
      _lanc(id: 'Ônibus', valorCents: 12000, categoria: 'Transporte', data: mes),
    ]);
    final metas = FakeMetasRepository([
      const Meta(id: 'm1', categoria: 'Alimentação', valorLimiteCents: 10000),
      const Meta(id: 'm2', categoria: 'Transporte', valorLimiteCents: 10000),
      const Meta(id: 'm3', categoria: 'Lazer', valorLimiteCents: 10000),
    ]);

    await _pump(tester, lancamentos: lancamentos, metas: metas);

    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('R\$ 90,00 de R\$ 100,00'), findsOneWidget);
    expect(find.text('90% · quase no limite'), findsOneWidget);
    expect(find.text('R\$ 120,00 de R\$ 100,00'), findsOneWidget);
    expect(find.text('120% · limite estourado'), findsOneWidget);
    expect(find.text('R\$ 0,00 de R\$ 100,00'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('MetasScreen mostra empty state quando não há metas',
      (tester) async {
    final lancamentos = FakeLancamentosRepository();
    final metas = FakeMetasRepository();

    await _pump(tester, lancamentos: lancamentos, metas: metas);

    expect(find.text('Nenhuma meta criada'), findsOneWidget);
    expect(find.text('Nova meta'), findsOneWidget);
  });

  testWidgets('criar meta pelo dialog chama repository.create', (tester) async {
    final lancamentos = FakeLancamentosRepository();
    final metas = FakeMetasRepository();

    await _pump(tester, lancamentos: lancamentos, metas: metas);

    await tester.tap(find.text('Nova meta'));
    await tester.pumpAndSettle();

    expect(find.text('Nova meta'), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '500,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(metas.createCount, 1);
    expect(metas.items.single.categoria, 'Mercado');
    expect(metas.items.single.valorLimiteCents, 50000);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('R\$ 0,00 de R\$ 500,00'), findsOneWidget);
  });

  testWidgets('editar e excluir meta pelo popup menu', (tester) async {
    final lancamentos = FakeLancamentosRepository();
    final metas = FakeMetasRepository([
      const Meta(id: 'm1', categoria: 'Mercado', valorLimiteCents: 10000),
    ]);

    await _pump(tester, lancamentos: lancamentos, metas: metas);

    // Editar.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar meta'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '600,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(metas.updateCount, 1);
    expect(metas.items.single.valorLimiteCents, 60000);

    // Excluir.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir meta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(metas.deleteCount, 1);
    expect(metas.items, isEmpty);
    expect(find.text('Nenhuma meta criada'), findsOneWidget);
  });
}