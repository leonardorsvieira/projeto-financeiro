import 'rendimento_investimento.dart';

abstract class RendimentosInvestimentoRepository {
  Stream<List<RendimentoInvestimento>> watchTodos();

  Future<RendimentoInvestimento> create(RendimentoInvestimento rendimento);

  Future<RendimentoInvestimento> update(RendimentoInvestimento rendimento);

  Future<void> delete(String id);
}