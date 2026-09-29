import 'investimento.dart';

abstract class InvestimentosRepository {
  Stream<List<Investimento>> watch();

  Future<Investimento> create(Investimento investimento);

  Future<Investimento> update(Investimento investimento);

  Future<void> delete(String id);

  /// Espelha as posições do Open Finance: cria/atualiza cada [importados]
  /// (casados por `pluggyId`) e, se [removerAusentes], apaga os importados
  /// antes que não vieram mais (resgatados ou conexão removida). O Patrimônio
  /// é só do Open Finance: quando [importados] não está vazio, os ativos
  /// antigos cadastrados à mão (sem `pluggyId`) são apagados. Devolve quantos
  /// ativos mudaram.
  Future<int> sincronizarOpenFinance(
    List<Investimento> importados, {
    required bool removerAusentes,
  });
}
