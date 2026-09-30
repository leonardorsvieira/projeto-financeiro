import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/presentation/investimento_detalhe_screen.dart';

import '../../../support/fake_investimentos_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeInvestimentosRepository investimentos,
  String id,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(investimentos),
      ],
      child: MaterialApp(
        home: InvestimentoDetalheScreen(investimentoId: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra a posição do Open Finance sem ações de edição',
      (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
        pluggyId: 'p1',
      ),
    ]);

    await _pump(tester, investimentos, 'i1');

    expect(find.text('PETR4'), findsOneWidget);
    expect(find.text('Patrimônio: R\$ 385,00'), findsOneWidget);
    expect(find.textContaining('Open Finance'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Registrar'), findsNothing);
  });

  testWidgets('ativo inexistente mostra mensagem', (tester) async {
    await _pump(tester, FakeInvestimentosRepository(), 'nao-existe');
    expect(find.text('Ativo não encontrado.'), findsOneWidget);
  });
}
