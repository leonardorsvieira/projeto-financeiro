import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento_converter.dart';

void main() {
  group('parseValorBRLParaCentavos', () {
    test('aceita vírgula decimal', () {
      expect(parseValorBRLParaCentavos('12,34'), 1234);
    });

    test('aceita ponto como milhar e vírgula decimal', () {
      expect(parseValorBRLParaCentavos('1.234,56'), 123456);
    });

    test('aceita ponto decimal simples', () {
      expect(parseValorBRLParaCentavos('999.99'), 99999);
    });

    test('rejeita 3 casas decimais', () {
      expect(parseValorBRLParaCentavos('12,345'), isNull);
      expect(parseValorBRLParaCentavos('12.345'), isNull);
    });

    test('rejeita vazio ou inválido', () {
      expect(parseValorBRLParaCentavos(''), isNull);
      expect(parseValorBRLParaCentavos('abc'), isNull);
    });

    test('rejeita zero e negativo', () {
      expect(parseValorBRLParaCentavos('0'), isNull);
      expect(parseValorBRLParaCentavos('-5,00'), isNull);
    });

    test('aceita símbolo R\$', () {
      expect(parseValorBRLParaCentavos(r'R$ 89,90'), 8990);
    });
  });

  group('formatoBRL', () {
    test('formata com símbolo e separador pt_BR', () {
      expect(formatoBRL(123456), 'R\$ 1.234,56');
    });

    test('formata centavos simples', () {
      expect(formatoBRL(99), 'R\$ 0,99');
    });

    test('formata zero', () {
      expect(formatoBRL(0), 'R\$ 0,00');
    });
  });

  group('formatoData', () {
    test('formata dd/MM/yyyy', () {
      expect(formatoData(DateTime(2026, 9, 6)), '06/09/2026');
    });
  });

  group('Lancamento', () {
    test('roundtrip toMap/fromMap preserva valores', () {
      final lancamento = Lancamento(
        id: 'abc-123',
        descricao: 'Feira',
        valorCents: 8990,
        categoria: 'Mercado',
        formaPagamento: 'Pix',
        data: DateTime(2026, 9, 6),
        vencimento: DateTime(2026, 9, 12),
        obs: 'início do mês',
        createdAt: DateTime.utc(2026, 9, 6, 12),
        updatedAt: DateTime.utc(2026, 9, 6, 12),
      );

      final parsed = Lancamento.fromMap(lancamento.toMap());

      expect(parsed.id, lancamento.id);
      expect(parsed.descricao, lancamento.descricao);
      expect(parsed.valorCents, lancamento.valorCents);
      expect(parsed.categoria, lancamento.categoria);
      expect(parsed.formaPagamento, lancamento.formaPagamento);
      expect(parsed.data, DateTime(2026, 9, 6));
      expect(parsed.vencimento, DateTime(2026, 9, 12));
      expect(parsed.obs, 'início do mês');
    });

    test('map usa date-only ISO para data/vencimento', () {
      final lancamento = Lancamento(
        id: 'x',
        descricao: 'X',
        valorCents: 100,
        categoria: 'Outros',
        formaPagamento: 'Dinheiro',
        data: DateTime(2026, 9, 6, 15, 30),
        createdAt: DateTime.utc(2026, 9, 6, 12),
        updatedAt: DateTime.utc(2026, 9, 6, 12),
      );

      final map = lancamento.toMap();
      expect(map['data'], '2026-09-06');
      expect(map['valor_cents'], 100);
      expect(map['vencimento'], isNull);
    });
  });
}