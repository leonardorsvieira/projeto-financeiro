import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (message.contains('password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns segundos e tente de novo.';
    }
    if (message.contains('network')) {
      return 'Falha de conexão. Verifique sua internet.';
    }
  }
  return 'Não foi possível concluir. Tente novamente.';
}