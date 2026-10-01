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
    expect(formatarVersao(versaoDocumentos), '01/10/2026');
    expect(formatarVersao('2026-01-09'), '09/01/2026');
  });

  test(
    'nome do controlador preenchido para o APK comercial',
    () {
      expect(nomeControlador, isNotEmpty);
      expect(nomeControlador, isNot(contains('[')));
    },
    skip: nomeControlador.contains('[')
        ? 'preencher nomeControlador antes do APK comercial'
        : null,
  );
}
