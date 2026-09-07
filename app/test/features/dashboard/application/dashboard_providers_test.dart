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
  required DateTime data,
  DateTime? vencimento,
}) {
  final agora = DateTime.now();
  return Lancamento(
    id: id,
    descricao: id,
    categoria: 'Outros',
    valorCents: valorCents,
    formaPagamento: 'Pix',
    data: data,
    vencimento: vencimento,
    createdAt: agora,
    updatedAt: agora,
  );
}

void main() {
  Future<void> aguardarEmissao(ProviderContainer c) {
    final completer = Completer<void>();
    late final ProviderSubscription sub;
    sub = c.listen(lancamentosStreamProvider, (_, next) {
      final data = (next as AsyncValue<List<Lancamento>>).value;
      if (data != null && !completer.isCompleted) {
        completer.complete();
        sub.close();
      }
    });
    return completer.future;
  }

  test('resumoMesProvider soma real do mês e previstos sem duplicar', () async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      // Real deste mês: soma.
      _lanc(id: '1', valorCents: 10000, data: mes.add(const Duration(days: 3))),
      // Previsto deste mês: vence este mês, data fora deste mês.
      _lanc(
        id: '2',
        valorCents: 5000,
        data: outroMes,
        vencimento: mes.add(const Duration(days: 10)),
      ),
      // Vence este mês MAS data também neste mês → conta como real, não previsto.
      _lanc(
        id: '3',
        valorCents: 2000,
        data: mes.add(const Duration(days: 1)),
        vencimento: mes.add(const Duration(days: 15)),
      ),
      // Fora do mês atual: ignora.
      _lanc(id: '4', valorCents: 99999, data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final resumo = container.read(resumoMesProvider);

    expect(resumo.realCents, 12000, reason: '1 + 3 com data no mês');
    expect(resumo.previstoCents, 5000, reason: 'somente lançamento 2');
    expect(resumo.totalCents, 17000);
  });

  test('resumoMesProvider zera quando nada no mês atual', () async {
    final agora = DateTime.now();
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      _lanc(id: '1', valorCents: 99999, data: outroMes),
    ]);

    final container = ProviderContainer(
      overrides: [lancamentosRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await aguardarEmissao(container);
    final resumo = container.read(resumoMesProvider);

    expect(resumo.realCents, 0);
    expect(resumo.previstoCents, 0);
  });
}