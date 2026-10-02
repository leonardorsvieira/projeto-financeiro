import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState;

import '../../privacidade/domain/aceite_termos.dart';
import '../domain/auth_state.dart';

/// Página (GitHub Pages) para onde o link de confirmação de cadastro leva.
/// Precisa estar em Authentication → URL Configuration → Redirect URLs.
const urlConfirmacaoEmail =
    'https://leonardorsvieira.github.io/projeto-financeiro/confirmado.html';

/// Troca erros do stream de autenticação pelo estado real da sessão.
///
/// Na web, o supabase_flutter lê o endereço ao iniciar; com um retorno de
/// verificação inválido (`?error=...&error_code=otp_expired`) ele emite um
/// ERRO em vez do estado inicial, o app ficava sem estado e o roteador preso
/// no splash. Com sessão a pessoa continua logada; sem, vai para o login.
Stream<AuthState> tolerarErrosDeSessao(
  Stream<AuthState> origem,
  AuthState Function() estadoAtual,
) {
  return origem.transform(
    StreamTransformer<AuthState, AuthState>.fromHandlers(
      handleError: (_, _, sink) => sink.add(estadoAtual()),
    ),
  );
}

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
    return tolerarErrosDeSessao(
      _auth.onAuthStateChange.map((data) => _estadoDe(data.session)),
      () => _estadoDe(_auth.currentSession),
    );
  }

  static AuthState _estadoDe(Session? sessao) => AuthState(
    sessao != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    email: sessao?.user.email,
    termosVersao: sessao?.user.userMetadata?['termos_versao']?.toString(),
  );

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
      // Celular e web: o link do e-mail termina na página "Cadastro
      // confirmado" (fora do app), nunca no app web, que não deve receber
      // tokens nem erros de verificação pelo endereço.
      emailRedirectTo: urlConfirmacaoEmail,
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