import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/core/auth_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const semAcesso =
      'Este e-mail ainda não tem acesso ao Meu Bolso. Fale com o vendedor.';

  group('friendlyAuthError', () {
    test('recusa do hook de cadastro vira a frase para o cliente', () {
      expect(
        friendlyAuthError(AuthException(semAcesso, statusCode: '403')),
        semAcesso,
      );
    });

    test('mensagem do hook embrulhada pelo Auth também', () {
      expect(
        friendlyAuthError(AuthException('Error running hook: $semAcesso')),
        semAcesso,
      );
    });

    test('credenciais inválidas seguem iguais', () {
      expect(
        friendlyAuthError(AuthException('Invalid login credentials')),
        'E-mail ou senha incorretos.',
      );
    });

    test('erro que não é do Auth segue o texto genérico', () {
      expect(
        friendlyAuthError(Exception('x')),
        'Não foi possível concluir. Tente novamente.',
      );
    });
  });
}
