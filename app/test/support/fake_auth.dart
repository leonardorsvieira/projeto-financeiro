import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/auth/data/auth_repository.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(AuthState initialState) : _state = initialState;

  AuthState _state;
  final _controller = StreamController<AuthState>.broadcast();
  Object? signInError;
  Object? signUpError;

  void emit(AuthState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  String? get currentEmail => _state.email;

  @override
  Stream<AuthState> get stateStream async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signOut() async {}
}

ProviderScope wrapWithFake(FakeAuthRepository fake, Widget child) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: child,
  );
}