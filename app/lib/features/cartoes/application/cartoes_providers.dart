import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cartoes_repository.dart';
import '../domain/cartao_credito.dart';

final cartoesRepositoryProvider = Provider<CartoesRepository>((ref) {
  return CartoesRepository();
});

class CartoesController extends AsyncNotifier<List<CartaoCredito>> {
  @override
  Future<List<CartaoCredito>> build() async {
    final repo = ref.read(cartoesRepositoryProvider);
    return repo.getCartoes();
  }

  Future<void> salvarCartao(CartaoCredito cartao) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cartoesRepositoryProvider);
      await repo.salvarCartao(cartao);
      return repo.getCartoes();
    });
  }

  Future<void> excluirCartao(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cartoesRepositoryProvider);
      await repo.excluirCartao(id);
      return repo.getCartoes();
    });
  }
}

final cartoesControllerProvider =
    AsyncNotifierProvider<CartoesController, List<CartaoCredito>>(
        CartoesController.new);
