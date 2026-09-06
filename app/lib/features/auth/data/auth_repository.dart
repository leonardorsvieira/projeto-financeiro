import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState;

import '../domain/auth_state.dart';

abstract class AuthRepository {
  Stream<AuthState> get stateStream;

  String? get currentEmail;

  Future<void> signUp(String email, String password);

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
      );
    });
  }

  @override
  String? get currentEmail => _auth.currentSession?.user.email;

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email: email, password: password);
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