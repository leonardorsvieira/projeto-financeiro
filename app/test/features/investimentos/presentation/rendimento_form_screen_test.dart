import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/rendimento_investimento.dart';
import 'package:meubolso/features/investimentos/presentation/rendimento_form_screen.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_rendimentos_investimento_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeInvestimentosRepository investimentos,
  required FakeRendimentosInvestimentoRepository rendimentos,
  required String investimentoId,
  RendimentoInvestimento? rendimento,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(investimentos),
        rendimentosInvestimentoRepositoryProvider.overrideWithValue(rendimentos),
      ],
      child: MaterialApp(
        home: RendimentoFormScreen(
          investimentoId: investimentoId,
          rendimento: rendimento,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const invId = 'i1';

  testWidgets('novo rendimento: formulario salva e fecha', (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository();

    await _pump(
      tester,
      investimentos: investimentos,
      rendimentos: rendimentos,
      investimentoId: invId,
    );

    expect(find.text('Novo rendimento'), findsOneWidget);
    expect(find.text('PETR4'), findsOneWidget);

    // Seleciona tipo Juros
    await tester.tap(find.byType(DropdownButtonFormField<TipoRendimentoInvestimento>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juros').last);
    await tester.pumpAndSettle();

    // Valor
    await tester.enterText(find.byType(TextField).at(0), '100,00');

    // Data (usa atual, não muda)

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(rendimentos.createCount, 1);
    expect(rendimentos.items.single.investimentoId, invId);
    expect(rendimentos.items.single.tipo, TipoRendimentoInvestimento.juros);
    expect(rendimentos.items.single.valorCents, 10000);
  });

  testWidgets('edição de rendimento chama update', (tester) async {
    final existing = RendimentoInvestimento(
      id: 'r1',
      investimentoId: invId,
      tipo: TipoRendimentoInvestimento.dividendo,
      valorCents: 5000,
      data: DateTime(2026, 8, 1),
    );
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository([existing]);

    await _pump(
      tester,
      investimentos: investimentos,
      rendimentos: rendimentos,
      investimentoId: invId,
      rendimento: existing,
    );

    expect(find.text('Editar rendimento'), findsOneWidget);
    expect(find.text('50,00'), findsOneWidget);

    // Altera valor
    await tester.enterText(find.byType(TextField).at(0), '75,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(rendimentos.updateCount, 1);
    expect(rendimentos.items.single.valorCents, 7500);
    expect(rendimentos.items.single.id, 'r1'); // id preservado
  });

  testWidgets('excluir rendimento com confirmação', (tester) async {
    final existing = RendimentoInvestimento(
      id: 'r1',
      investimentoId: invId,
      tipo: TipoRendimentoInvestimento.dividendo,
      valorCents: 5000,
      data: DateTime(2026, 8, 1),
    );
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository([existing]);

    await _pump(
      tester,
      investimentos: investimentos,
      rendimentos: rendimentos,
      investimentoId: invId,
      rendimento: existing,
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Excluir rendimento?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(rendimentos.deleteCount, 1);
    expect(rendimentos.items, isEmpty);
  });

  testWidgets('valor inválido mostra erro', (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: invId,
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);
    final rendimentos = FakeRendimentosInvestimentoRepository();

    await _pump(
      tester,
      investimentos: investimentos,
      rendimentos: rendimentos,
      investimentoId: invId,
    );

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um valor válido.'), findsOneWidget);
    expect(rendimentos.createCount, 0);
  });
}