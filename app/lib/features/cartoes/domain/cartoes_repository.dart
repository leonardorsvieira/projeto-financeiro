import 'cartao_credito.dart';

/// Cartões de crédito do usuário logado.
abstract class CartoesRepository {
  Future<List<CartaoCredito>> listar();

  /// Cria (id vazio) ou atualiza o cartão.
  Future<void> salvar(CartaoCredito cartao);

  Future<void> excluir(String id);

  /// O usuário já respondeu "quais cartões você usa?" (inclusive "não uso").
  Future<bool> perguntaRespondida();

  Future<void> marcarPerguntaRespondida();
}
