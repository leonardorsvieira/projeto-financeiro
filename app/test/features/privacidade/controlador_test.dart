import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/domain/documento_legal.dart';

void main() {
  test('emailPrivacidade tem formato de e-mail', () {
    expect(emailPrivacidade, matches(RegExp(r'^\S+@\S+\.\S+$')));
  });

  test('versaoDocumentos é uma data ISO válida', () {
    expect(() => DateTime.parse(versaoDocumentos), returnsNormally);
  });

  test('formatarVersao devolve dia/mês/ano', () {
    expect(formatarVersao(versaoDocumentos), '03/10/2026');
    expect(formatarVersao('2026-01-09'), '09/01/2026');
  });

  test('CNPJ do controlador tem dígitos verificadores válidos', () {
    final d = cnpjControlador.replaceAll(RegExp(r'\D'), '').split('').map(int.parse).toList();
    expect(d, hasLength(14));
    int dv(int n) {
      final pesos = n == 12
          ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
          : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      var soma = 0;
      for (var i = 0; i < n; i++) {
        soma += d[i] * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    expect(d[12], dv(12));
    expect(d[13], dv(13));
  });

  test('identificação do controlador nos documentos', () {
    expect(identificacaoControlador, contains(cnpjControlador));
    expect(identificacaoControlador, isNot(contains('[')));
  });
}
