import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/domain/movimento_investimento.dart';

void main() {
  group('TipoMovimentoInvestimento', () {
    test('dbValue/rotulo corretos', () {
      expect(TipoMovimentoInvestimento.compra.dbValue, 'compra');
      expect(TipoMovimentoInvestimento.compra.rotulo, 'Compra');
      expect(TipoMovimentoInvestimento.venda.dbValue, 'venda');
      expect(TipoMovimentoInvestimento.venda.rotulo, 'Venda');
      expect(
        TipoMovimentoInvestimento.fromDb('venda'),
        TipoMovimentoInvestimento.venda,
      );
      expect(
        TipoMovimentoInvestimento.fromDb('desconhecido'),
        TipoMovimentoInvestimento.compra,
      );
    });
  });

  group('MovimentoInvestimento', () {
    test('valorCents = qtd × preço', () {
      final mov = MovimentoInvestimento(
        id: 'm1',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 10,
        precoUnitCents: 3850,
        data: _d(2026, 9, 1),
      );
      expect(mov.valorCents, 38500);
    });

    test('toMap/fromMap roundtrip', () {
      final mov = MovimentoInvestimento(
        id: 'm1',
        investimentoId: 'i1',
        tipo: TipoMovimentoInvestimento.compra,
        quantidade: 10.5,
        precoUnitCents: 3850,
        data: DateTime(2026, 9, 1, 14, 30),
      );
      final fromMap = MovimentoInvestimento.fromMap(mov.toMap());
      expect(fromMap.id, mov.id);
      expect(fromMap.investimentoId, mov.investimentoId);
      expect(fromMap.tipo, mov.tipo);
      expect(fromMap.quantidade, mov.quantidade);
      expect(fromMap.precoUnitCents, mov.precoUnitCents);
      expect(fromMap.data, DateTime(2026, 9, 1));
    });
  });
}

DateTime _d(int y, int m, int d) => DateTime(y, m, d);
