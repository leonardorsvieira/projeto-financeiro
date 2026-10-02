import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    // Recusa do hook "Before User Created" (e-mail sem acesso liberado).
    if (message.contains('não tem acesso')) {
      return 'Este e-mail ainda não tem acesso ao Meu Bolso. Fale com o vendedor.';
    }
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (error is AuthWeakPasswordException ||
        message.contains('password should') ||
        message.contains('weak')) {
      return 'Senha fraca: use pelo menos 9 caracteres, com letra minúscula, '
          'maiúscula, número e símbolo.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns segundos e tente novamente.';
    }
    if (message.contains('network')) {
      return 'Sem conexão. Verifique sua internet e tente novamente.';
    }
  }
  return 'Não foi possível concluir. Tente novamente.';
}