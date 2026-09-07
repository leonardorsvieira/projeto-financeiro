import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/rendimento_investimento.dart';
import 'package:meubolso/features/investimentos/presentation/rendimentos_screen.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_rendimentos_investimento_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeInvestimentosRepository investimentos,
  required FakeRendimentosInvestimentoRepository rendimentos,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investimentosRepositoryProvider.overrideWithValue(investimentos),
        rendimentosInvestimentoRepositoryProvider.overrideWithValue(rendimentos),
      ],
      child: const MaterialApp(home: RendimentosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem rendimentos mostra empty state', (tester) async {
    await _pump(
      tester,
      investimentos: FakeInvestimentosRepository(),
      rendimentos: FakeRendimentosInvestimentoRepository(),
    );

    expect(find.text('Rendimentos'), findsOneWidget);
expect(find.text('Nenhum rendimento recebido'), findsOneWidget);
    expect(find.text('Dividendos, juros e outros rendimentos aparecem aqui, somados por mês.'), findsOneWidget);
  });

  testWidgets('mostra rendimentos agrupados por mês com total', (tester) async {
    final investimentos = FakeInvestimentosRepository([
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
      // Setembro 2026 - mais recente
      RendimentoInvestimento(
        id: 'r1',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 7000,
        data: DateTime(2026, 9, 5),
      ),
      // Agosto 2026
      RendimentoInvestimento(
        id: 'r2',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 5000,
        data: DateTime(2026, 8, 15),
      ),
      RendimentoInvestimento(
        id: 'r3',
        investimentoId: 'i2',
        tipo: TipoRendimentoInvestimento.juros,
        valorCents: 3000,
        data: DateTime(2026, 8, 10),
      ),
      // Julho 2026
      RendimentoInvestimento(
        id: 'r4',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 2000,
        data: DateTime(2026, 7, 20),
      ),
    ]);

    await _pump(
      tester,
      investimentos: investimentos,
      rendimentos: rendimentos,
    );

    // Ordem: Setembro, Agosto, Julho
    expect(find.text('Setembro 2026'), findsOneWidget);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Julho 2026'), findsOneWidget);

    // Total de Setembro
    expect(find.text('R\$ 70,00'), findsWidgets); // total do mês + tile
    // Total de Agosto (5000 + 3000 = 8000)
    expect(find.text('R\$ 80,00'), findsWidgets);
    // Total de Julho
    expect(find.text('R\$ 20,00'), findsWidgets);

    // Verifica itens individuais com nome do ativo
    expect(find.text('PETR4'), findsWidgets);
    expect(find.text('XPML11'), findsOneWidget);
  });
}