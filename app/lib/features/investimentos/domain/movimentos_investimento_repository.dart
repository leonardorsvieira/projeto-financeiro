import 'movimento_investimento.dart';

abstract class MovimentosInvestimentoRepository {
  Stream<List<MovimentoInvestimento>> watchPorInvestimento(String investimentoId);

  Future<MovimentoInvestimento> create(MovimentoInvestimento movimento);

  Future<void> delete(String id);
}
