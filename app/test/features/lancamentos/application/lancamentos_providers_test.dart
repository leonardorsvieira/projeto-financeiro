import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../support/fake_lancamentos_repository.dart';

Lancamento _armario({String? id}) {
  return Lancamento(
    id: id ?? 'armario',
    descricao: 'Armário',
    valorCents: 150000,
    categoria: 'Moradia',
    formaPagamento: 'Cartão de Crédito',
    data: DateTime(2026, 9, 5),
    createdAt: DateTime.utc(2026, 9, 5),
    updatedAt: DateTime.utc(2026, 9, 5),
  );
}

void main() {
  late FakeLancamentosRepository fake;

  ProviderContainer container({List<Lancamento>? seed}) {
    fake = FakeLancamentosRepository(seed);
    final c = ProviderContainer(
      overrides: [
        lancamentosRepositoryProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<List<Lancamento>> waitEmission(
    ProviderContainer c,
    bool Function(List<Lancamento>) pred,
  ) {
    final completer = Completer<List<Lancamento>>();
    late final ProviderSubscription sub;
    sub = c.listen(lancamentosStreamProvider, (_, next) {
      final data = (next as AsyncValue<List<Lancamento>>).value;
      if (data != null && pred(data) && !completer.isCompleted) {
        completer.complete(data);
        sub.close();
      }
    });
    return completer.future;
  }

  test('lancamentosStreamProvider emite itens seeds', () async {
    final c = container(seed: [_armario()]);

    final first = await waitEmission(c, (_) => true);
    expect(first, hasLength(1));
    expect(first.first.descricao, 'Armário');
    expect(first.first.valorCents, 150000);
  });

  test('criação via repo reflete no stream', () async {
    final c = container();
    await waitEmission(c, (_) => true);

    await c.read(lancamentosRepositoryProvider).create(
          descricao: 'Mercado',
          valorCents: 8990,
          categoria: 'Mercado',
          formaPagamento: 'Pix',
          data: DateTime(2026, 9, 6),
        );

    final second = await waitEmission(c, (l) => l.isNotEmpty);
    expect(second, hasLength(1));
    expect(second.first.descricao, 'Mercado');
    expect(fake.createCount, 1);
  });

  test('deleção via repo reflete no stream', () async {
    final item = _armario();
    final c = container(seed: [item]);
    await waitEmission(c, (_) => true);

    await c.read(lancamentosRepositoryProvider).delete(item.id);

    final second = await waitEmission(c, (l) => l.isEmpty);
    expect(second, isEmpty);
    expect(fake.deleteCount, 1);
  });

  test('lancamentoByIdProvider busca por id', () async {
    final c = container(seed: [_armario()]);

    final l = await c.read(lancamentoByIdProvider('armario').future);
    expect(l?.descricao, 'Armário');
  });
}