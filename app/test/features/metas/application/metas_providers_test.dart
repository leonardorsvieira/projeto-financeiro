import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/metas/application/metas_providers.dart';
import 'package:meubolso/features/metas/domain/meta.dart';

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
    createdAt: agora,
    updatedAt: agora,
  );
}

Future<void> _aguardar(ProviderContainer c) {
  final completer = Completer<void>();
  bool lancamentosEmitiu = false;
  bool metasEmitiu = false;

  void check() {
    if (lancamentosEmitiu && metasEmitiu && !completer.isCompleted) {
      completer.complete();
    }
  }

  c.listen(lancamentosStreamProvider, (_, next) {
    if (next.value != null) {
      lancamentosEmitiu = true;
      check();
    }
  });
  c.listen(metasStreamProvider, (_, next) {
    if (next.value != null) {
      metasEmitiu = true;
      check();
    }
  });

  return completer.future;
}

void main() {
  test('metasComProgressoProvider calcula percentual e flag de estouro', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final lancRepo = FakeLancamentosRepository([
      _lanc(
          id: 'a',
          valorCents: 9000,
          categoria: 'Alimentação',
          data: mes),
      _lanc(id: 'b', valorCents: 5000, categoria: 'Transporte', data: mes),
    ]);
    final metasRepo = FakeMetasRepository([
      const Meta(
          id: 'm1', categoria: 'Alimentação', valorLimiteCents: 10000),
      const Meta(
          id: 'm2', categoria: 'Transporte', valorLimiteCents: 10000),
      const Meta(id: 'm3', categoria: 'Lazer', valorLimiteCents: 10000),
    ]);

    final container = ProviderContainer(
      overrides: [
        lancamentosRepositoryProvider.overrideWithValue(lancRepo),
        metasRepositoryProvider.overrideWithValue(metasRepo),
      ],
    );
    addTearDown(container.dispose);

    await _aguardar(container);

    final progressos = container.read(metasComProgressoProvider);
    expect(progressos, hasLength(3));

    final alimentacao = progressos
        .firstWhere((p) => p.meta.categoria == 'Alimentação');
    expect(alimentacao.gastoCents, 9000);
    expect(alimentacao.percentual, 90);
    expect(alimentacao.estourou, isFalse);
    expect(alimentacao.quaseEstourada, isTrue);

    final transporte = progressos.firstWhere((p) => p.meta.categoria == 'Transporte');
    expect(transporte.gastoCents, 5000);
    expect(transporte.percentual, 50);
    expect(transporte.estourou, isFalse);
    expect(transporte.quaseEstourada, isFalse);

    final lazer = progressos.firstWhere((p) => p.meta.categoria == 'Lazer');
    expect(lazer.gastoCents, 0);
    expect(lazer.percentual, 0);
  });

  test('metasComProgressoProvider marca estouro quando percentual > 100', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final lancRepo = FakeLancamentosRepository([
      _lanc(
          id: 'a',
          valorCents: 12000,
          categoria: 'Mercado',
          data: mes),
    ]);
    final metasRepo = FakeMetasRepository([
      const Meta(id: 'm1', categoria: 'Mercado', valorLimiteCents: 10000),
    ]);

    final container = ProviderContainer(
      overrides: [
        lancamentosRepositoryProvider.overrideWithValue(lancRepo),
        metasRepositoryProvider.overrideWithValue(metasRepo),
      ],
    );
    addTearDown(container.dispose);

    await _aguardar(container);

    final progressos = container.read(metasComProgressoProvider);
    expect(progressos, hasLength(1));
    expect(progressos.single.gastoCents, 12000);
    expect(progressos.single.percentual, 120);
    expect(progressos.single.estourou, isTrue);
  });
}