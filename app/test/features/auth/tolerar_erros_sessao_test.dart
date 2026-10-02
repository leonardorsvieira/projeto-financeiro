import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/data/auth_repository.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';

void main() {
  test('erro do stream vira o estado atual (sem sessão → deslogado)',
      () async {
    final origem = StreamController<AuthState>();
    final recebidos = <AuthState>[];
    final sub = tolerarErrosDeSessao(
      origem.stream,
      () => const AuthState(AuthStatus.unauthenticated),
    ).listen(recebidos.add, onError: (_) => fail('erro não deveria vazar'));

    origem.addError(Exception('otp_expired'));
    await Future<void>.delayed(Duration.zero);

    expect(recebidos.single.status, AuthStatus.unauthenticated);
    await sub.cancel();
    await origem.close();
  });

  test('com sessão ativa, um erro não derruba o login', () async {
    final origem = StreamController<AuthState>();
    final recebidos = <AuthState>[];
    final sub = tolerarErrosDeSessao(
      origem.stream,
      () => const AuthState(AuthStatus.authenticated, email: 'a@b.com'),
    ).listen(recebidos.add);

    origem.add(const AuthState(AuthStatus.authenticated, email: 'a@b.com'));
    origem.addError(Exception('refresh falhou'));
    await Future<void>.delayed(Duration.zero);

    expect(recebidos.map((e) => e.status),
        [AuthStatus.authenticated, AuthStatus.authenticated]);
    await sub.cancel();
    await origem.close();
  });

  test('link de confirmação sempre vai para a página confirmado.html', () {
    expect(urlConfirmacaoEmail, endsWith('/projeto-financeiro/confirmado.html'));
    expect(urlConfirmacaoEmail, startsWith('https://'));
  });
}
