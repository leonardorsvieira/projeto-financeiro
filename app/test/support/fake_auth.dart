import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meubolso/features/acesso/application/acesso_providers.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/auth/data/auth_repository.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';

import 'fake_acesso_repository.dart';

/// Repositório de autenticação falso.
///
/// Com [termosEmDia] true (padrão), todo estado autenticado sem versão de
/// termos (inicial ou vindo de [emit]) é normalizado para a versão vigente,
/// de modo que os testes que só querem "um usuário logado" passam pelo portão
/// de re-aceite sem mudança. Para testar o portão, use `termosEmDia: false`
/// ou informe uma `termosVersao` antiga explícita.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(AuthState initialState, {this.termosEmDia = true})
    : _state = _normalizar(initialState, termosEmDia);

  final bool termosEmDia;
  AuthState _state;
  final _controller = StreamController<AuthState>.broadcast();
  Object? signInError;
  Object? signUpError;
  bool signUpExigeConfirmacao = false;

  /// Metadados enviados ao `signUp` mais recente (null se nunca chamado).
  Map<String, dynamic>? ultimoSignUpMetadados;

  /// Versão gravada por `aceitarTermos` (null se nunca chamado).
  String? termosAceitos;
  Object? aceitarTermosErro;
  int signOutChamadas = 0;

  static AuthState _normalizar(AuthState estado, bool termosEmDia) {
    if (termosEmDia &&
        estado.isAuthenticated &&
        estado.termosVersao == null) {
      return AuthState(
        estado.status,
        email: estado.email,
        termosVersao: versaoDocumentos,
      );
    }
    return estado;
  }

  void emit(AuthState state) {
    _state = _normalizar(state, termosEmDia);
    _controller.add(_state);
  }

  @override
  String? get currentEmail => _state.email;

  @override
  Stream<AuthState> get stateStream async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<bool> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadados,
  }) async {
    if (signUpError != null) throw signUpError!;
    ultimoSignUpMetadados = metadados;
    return signUpExigeConfirmacao;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> aceitarTermos(String versao) async {
    if (aceitarTermosErro != null) throw aceitarTermosErro!;
    termosAceitos = versao;
    emit(
      AuthState(_state.status, email: _state.email, termosVersao: versao),
    );
  }

  @override
  Future<void> signOut() async {
    signOutChamadas++;
    emit(const AuthState(AuthStatus.unauthenticated));
  }
}

ProviderScope wrapWithFake(FakeAuthRepository fake, Widget child) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      // Padrão: conta ativa, então o portão de acesso não interfere.
      acessoRepositoryProvider.overrideWithValue(FakeAcessoRepository()),
    ],
    child: child,
  );
}
