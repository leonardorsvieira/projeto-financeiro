import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/dashboard/application/saudacao.dart';

void main() {
  test('saudação por faixa de horário, com e sem nome', () {
    expect(saudacaoPara(DateTime(2026, 9, 30, 8), 'Ana'), 'Bom dia, Ana.');
    expect(saudacaoPara(DateTime(2026, 9, 30, 12), null), 'Boa tarde.');
    expect(saudacaoPara(DateTime(2026, 9, 30, 17, 59), ' '), 'Boa tarde.');
    expect(saudacaoPara(DateTime(2026, 9, 30, 18), 'Ana'), 'Boa noite, Ana.');
  });

  test('data por extenso com inicial maiúscula', () {
    expect(
      dataPorExtenso(DateTime(2026, 9, 30)),
      'Quarta-feira, 30 de setembro',
    );
  });
}
