enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState(this.status, {this.email});

  final AuthStatus status;
  final String? email;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.email == email;

  @override
  int get hashCode => Object.hash(status, email);
}