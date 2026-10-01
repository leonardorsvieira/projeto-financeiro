import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../privacidade/domain/aceite_termos.dart';
import '../../privacidade/domain/controlador.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);

final authControllerProvider =
    StreamNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends StreamNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Stream<AuthState> build() {
    return _repo.stateStream;
  }

  Future<void> signIn(String email, String password) {
    return _repo.signIn(email.trim(), password);
  }

  /// true = conta criada, falta confirmar o e-mail. O cadastro só é possível
  /// com a caixa de aceite marcada, então todo signUp leva a evidência do
  /// aceite (versão e data) nos metadados.
  Future<bool> signUp(String email, String password) {
    return _repo.signUp(
      email.trim(),
      password,
      metadados: metadadosDeAceite(),
    );
  }

  /// Registra o aceite da versão vigente dos documentos (re-aceite).
  Future<void> aceitarTermos() => _repo.aceitarTermos(versaoDocumentos);

  Future<void> signOut() {
    return _repo.signOut();
  }
}

/// Primeiro nome da conta (user_metadata `full_name` ou `name`), ou null.
/// Sem Supabase inicializado (testes) devolve null.
final primeiroNomeUsuarioProvider = Provider<String?>((ref) {
  ref.watch(authControllerProvider);
  try {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final bruto = (meta?['full_name'] ?? meta?['name'])?.toString().trim();
    if (bruto == null || bruto.isEmpty) return null;
    return bruto.split(RegExp(r's+')).first;
  } catch (_) {
    return null;
  }
});
