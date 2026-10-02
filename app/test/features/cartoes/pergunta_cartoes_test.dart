import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/cartoes/application/cartoes_providers.dart';
import 'package:meubolso/features/cartoes/presentation/pergunta_cartoes.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';

import '../../support/fake_cartoes_repository.dart';
import '../../support/fake_lancamentos_repository.dart';

final _agora = DateTime(2026, 10, 2);

Lancamento _importado(String forma) => Lancamento(
      id: forma,
      descricao: 'compra',
      valorCents: 1000,
      categoria: 'Outros',
      formaPagamento: forma,
      data: _agora,
      obs: 'pluggy_id:$forma',
      createdAt: _agora,
      updatedAt: _agora,
    );

Widget _app(FakeCartoesRepository cartoes, List<Lancamento> lancamentos) {
  return ProviderScope(
    overrides: [
      cartoesRepositoryProvider.overrideWithValue(cartoes),
      lancamentosRepositoryProvider
          .overrideWithValue(FakeLancamentosRepository(lancamentos)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => perguntarCartoes(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sugere os cartões que vieram do banco', (tester) async {
    final cartoes = FakeCartoesRepository(respondida: false);
    await tester.pumpWidget(_app(cartoes, [_importado('Cartão: gold')]));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Quais cartões de crédito você usa?'), findsOneWidget);
    expect(find.text('gold'), findsOneWidget);
    expect(find.text('Nubank'), findsNothing);

    // Tocar na sugestão abre o cadastro com o nome preenchido.
    await tester.tap(find.text('gold'));
    await tester.pumpAndSettle();
    expect(find.text('Novo cartão de crédito'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'gold',
    );
  });

  testWidgets('"Não uso cartão de crédito" grava a resposta e fecha',
      (tester) async {
    final cartoes = FakeCartoesRepository(respondida: false);
    await tester.pumpWidget(_app(cartoes, const []));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Não uso cartão de crédito'));
    await tester.pumpAndSettle();

    expect(cartoes.respondida, isTrue);
    expect(cartoes.marcarCount, 1);
    expect(find.text('Quais cartões de crédito você usa?'), findsNothing);
  });
}
