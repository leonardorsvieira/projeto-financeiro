import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/domain/rendimento_investimento.dart';

void main() {
  group('TipoRendimentoInvestimento', () {
    test('dbValue e rotulo corretos', () {
      expect(TipoRendimentoInvestimento.dividendo.dbValue, 'dividendo');
      expect(TipoRendimentoInvestimento.dividendo.rotulo, 'Dividendo');
      expect(TipoRendimentoInvestimento.juros.dbValue, 'juros');
      expect(TipoRendimentoInvestimento.juros.rotulo, 'Juros');
      expect(TipoRendimentoInvestimento.rendimento.dbValue, 'rendimento');
      expect(TipoRendimentoInvestimento.rendimento.rotulo, 'Rendimento');
      expect(TipoRendimentoInvestimento.outro.dbValue, 'outro');
      expect(TipoRendimentoInvestimento.outro.rotulo, 'Outro');
    });

    test('fromDb mapeia valores conhecidos', () {
      expect(
        TipoRendimentoInvestimento.fromDb('dividendo'),
        TipoRendimentoInvestimento.dividendo,
      );
      expect(
        TipoRendimentoInvestimento.fromDb('juros'),
        TipoRendimentoInvestimento.juros,
      );
      expect(
        TipoRendimentoInvestimento.fromDb('rendimento'),
        TipoRendimentoInvestimento.rendimento,
      );
      expect(
        TipoRendimentoInvestimento.fromDb('outro'),
        TipoRendimentoInvestimento.outro,
      );
    });

    test('fromDb desconhecido cai em rendimento', () {
      expect(
        TipoRendimentoInvestimento.fromDb('desconhecido'),
        TipoRendimentoInvestimento.rendimento,
      );
    });
  });

  group('RendimentoInvestimento', () {
    test('toMap/fromMap roundtrip', () {
      final original = RendimentoInvestimento(
        id: 'r1',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 15000,
        data: DateTime(2026, 8, 15),
      );
      final map = original.toMap();
      final restored = RendimentoInvestimento.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.investimentoId, original.investimentoId);
      expect(restored.tipo, original.tipo);
      expect(restored.valorCents, original.valorCents);
      expect(restored.data, original.data);
    });

    test('fromMap aceita números como num', () {
      final map = {
        'id': 'r1',
        'investimento_id': 'i1',
        'tipo': 'juros',
        'valor_cents': 2500,
        'data': '2026-08-15',
      };
      final r = RendimentoInvestimento.fromMap(map);
      expect(r.valorCents, 2500);
    });

    test('copyWith preserva valores não alterados', () {
      final original = RendimentoInvestimento(
        id: 'r1',
        investimentoId: 'i1',
        tipo: TipoRendimentoInvestimento.dividendo,
        valorCents: 10000,
        data: DateTime(2026, 8, 1),
      );
      final alterado = original.copyWith(tipo: TipoRendimentoInvestimento.juros);
      expect(alterado.id, 'r1');
      expect(alterado.investimentoId, 'i1');
      expect(alterado.tipo, TipoRendimentoInvestimento.juros);
      expect(alterado.valorCents, 10000);
      expect(alterado.data, DateTime(2026, 8, 1));
    });
  });
}