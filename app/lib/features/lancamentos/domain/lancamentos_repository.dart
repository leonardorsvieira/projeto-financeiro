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

  /// Lançamentos importados da Pluggy: `obs` (`pluggy_id:<transação>`) →
  /// descrição, para a sincronização não duplicar e atualizar descrições.
  Future<Map<String, String>> importadasPluggy();

  /// Troca a descrição do importado [obs] para [para] só se ela ainda for
  /// [de] (não desfaz uma edição do usuário).
  Future<void> renomearImportada(
    String obs, {
    required String de,
    required String para,
  });

  // Recorrência
  Future<Lancamento?> gerarProximaCopiaSeFixa(Lancamento lancamento);
  Future<void> ensureVigenteCopies();
  Future<void> excluirSerie(String serieId);
}