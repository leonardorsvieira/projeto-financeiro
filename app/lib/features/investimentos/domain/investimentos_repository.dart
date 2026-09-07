import 'investimento.dart';

abstract class InvestimentosRepository {
  Stream<List<Investimento>> watch();

  Future<Investimento> create(Investimento investimento);

  Future<Investimento> update(Investimento investimento);

  Future<void> delete(String id);
}
