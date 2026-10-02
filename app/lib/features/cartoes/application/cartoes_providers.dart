import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lancamentos/application/lancamentos_providers.dart';
import '../data/supabase_cartoes_repository.dart';
import '../domain/cartao_credito.dart';
import '../domain/cartoes_repository.dart';
import '../domain/formas_pagamento.dart';

final cartoesRepositoryProvider = Provider<CartoesRepository>(
  (ref) => SupabaseCartoesRepository(),
);

class CartoesController extends AsyncNotifier<List<CartaoCredito>> {
  CartoesRepository get _repo => ref.read(cartoesRepositoryProvider);

  @override
  Future<List<CartaoCredito>> build() =>
      ref.watch(cartoesRepositoryProvider).listar();

  /// Erros (ex.: assinatura vencida bloqueia a gravação) sobem para a tela;
  /// a lista atual continua na tela.
  Future<void> salvarCartao(CartaoCredito cartao) async {
    await _repo.salvar(cartao);
    state = AsyncData(await _repo.listar());
  }

  Future<void> excluirCartao(String id) async {
    await _repo.excluir(id);
    state = AsyncData(await _repo.listar());
  }
}

final cartoesControllerProvider =
    AsyncNotifierProvider<CartoesController, List<CartaoCredito>>(
      CartoesController.new,
    );

/// Formas de pagamento do usuário (formulário, ditado e confirmação).
final formasPagamentoProvider = Provider<List<String>>((ref) {
  final cartoes = ref.watch(cartoesControllerProvider).value ?? const [];
  return formasPagamentoDoUsuario(cartoes);
});

/// Cartões que aparecem nos lançamentos importados do banco e ainda não foram
/// cadastrados.
final sugestoesCartoesProvider = Provider<List<String>>((ref) {
  final lancamentos = ref.watch(lancamentosStreamProvider).value ?? const [];
  final cartoes = ref.watch(cartoesControllerProvider).value ?? const [];
  return sugestoesDeCartoes(lancamentos, cartoes);
});
