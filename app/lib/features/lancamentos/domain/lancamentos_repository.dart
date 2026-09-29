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
    List<LancamentoItem>? itens,
    bool fixoMensal = false,
    String? serieId,
    TipoLancamento tipo = TipoLancamento.despesa,
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
    List<LancamentoItem>? itens,
    bool? fixoMensal,
    String? serieId,
    TipoLancamento? tipo,
  });

  Future<void> delete(String id);

  Future<Lancamento?> findById(String id);

  /// `obs` de todos os lançamentos importados da Pluggy
  /// (`pluggy_id:<transação>`), para a sincronização não duplicar.
  Future<Set<String>> obsImportadasPluggy();

  // Recorrência
  Future<Lancamento?> gerarProximaCopiaSeFixa(Lancamento lancamento);
  Future<void> ensureVigenteCopies();
  Future<void> excluirSerie(String serieId);
}