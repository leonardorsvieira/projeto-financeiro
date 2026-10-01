enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState(this.status, {this.email, this.termosVersao});

  final AuthStatus status;
  final String? email;

  /// Versão dos Termos/Política que a conta aceitou (user_metadata
  /// `termos_versao`); null se nunca aceitou.
  final String? termosVersao;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.email == email &&
          other.termosVersao == termosVersao;

  @override
  int get hashCode => Object.hash(status, email, termosVersao);
}
