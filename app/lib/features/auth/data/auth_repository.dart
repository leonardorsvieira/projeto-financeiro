import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState;

import '../../privacidade/domain/aceite_termos.dart';
import '../domain/auth_state.dart';

abstract class AuthRepository {
  Stream<AuthState> get stateStream;

  String? get currentEmail;

  /// Cria a conta. Devolve true quando é preciso confirmar o e-mail antes de
  /// entrar (o Supabase não abre sessão até o clique no link).
  ///
  /// [metadados] vão para o `user_metadata` do usuário (evidência do aceite
  /// dos termos, ver `metadadosDeAceite`).
  Future<bool> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadados,
  });

  /// Registra no usuário o aceite da versão [versao] dos documentos legais.
  Future<void> aceitarTermos(String versao);

  Future<void> signIn(String email, String password);

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Stream<AuthState> get stateStream {
    return _auth.onAuthStateChange.map((data) {
      return AuthState(
        data.session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        email: data.session?.user.email,
        termosVersao: data.session?.user.userMetadata?['termos_versao']
            ?.toString(),
      );
    });
  }

  @override
  String? get currentEmail => _auth.currentSession?.user.email;

  @override
  Future<bool> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadados,
  }) async {
    final resposta = await _auth.signUp(
      email: email,
      password: password,
      // Na web, o link de confirmação volta para este mesmo site.
      emailRedirectTo: kIsWeb ? Uri.base.removeFragment().toString() : null,
      data: metadados,
    );
    return resposta.session == null;
  }

  @override
  Future<void> aceitarTermos(String versao) async {
    // O Supabase faz merge do user_metadata (preserva full_name) e emite
    // userUpdated com a sessão atualizada, o que reemite o AuthState.
    await _auth.updateUser(
      UserAttributes(data: metadadosDeAceite(versao: versao)),
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}