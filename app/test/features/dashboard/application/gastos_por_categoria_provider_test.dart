import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/dashboard/application/dashboard_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';

import '../../../support/fake_lancamentos_repository.dart';

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
  late final ProviderSubscription sub;
  sub = c.listen(lancamentosStreamProvider, (_, next) {
    if ((next as AsyncValue<List<Lancamento>>).value != null &&
        !completer.isCompleted) {
      completer.complete();
      sub.close();
    }
  });
  return completer.future;
}

void main() {
  test('gastosPorCategoriaMesProvider agrupa e ordena por categoria', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      _lanc(id: 'a', valorCents: 1000, categoria: 'Mercado', data: mes),
      _lanc(id: 'b', valorCents: 5000, categoria: 'Transporte', data: mes),
      _lanc(id: 'c', valorCents: 2000, categoria: 'Mercado', data: mes),
      _lanc(id: 'd', valorCents: 9000, categoria: 'Alimentação', data: mes),
      // Fora do mês: deve ser ignorado.
      _lanc(id: 'e', valorCents: 99999, categoria: 'Lazer', data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await _aguardar(container);
    final gastos = container.read(gastosPorCategoriaMesProvider);

    expect(gastos, hasLength(3));
    expect(gastos[0].categoria, 'Alimentação');
    expect(gastos[0].valorCents, 9000);
    expect(gastos[1].categoria, 'Transporte');
    expect(gastos[1].valorCents, 5000);
    expect(gastos[2].categoria, 'Mercado');
    expect(gastos[2].valorCents, 3000);
  });

  test('gastosPorCategoriaMesProvider vazio quando não há gastos no mês',
      () async {
    final agora = DateTime.now();
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      _lanc(id: 'a', valorCents: 1000, categoria: 'Lazer', data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await _aguardar(container);
    expect(container.read(gastosPorCategoriaMesProvider), isEmpty);
  });
}