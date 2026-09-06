import 'lancamento.dart';

abstract class LancamentosRepository {
  Stream<List<Lancamento>> watch();

  Future<Lancamento> create({
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  });

  Future<Lancamento> update(
    Lancamento lancamento, {
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  });

  Future<void> delete(String id);

  Future<Lancamento?> findById(String id);
}