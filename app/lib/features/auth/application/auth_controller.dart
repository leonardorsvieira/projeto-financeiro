import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> signUp(String email, String password) {
    return _repo.signUp(email.trim(), password);
  }

  Future<void> signOut() {
    return _repo.signOut();
  }
}