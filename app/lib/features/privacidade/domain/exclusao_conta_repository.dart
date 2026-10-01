/// Exclusão da própria conta (LGPD, art. 18, VI): apaga os dados do servidor e
/// desconecta os bancos do Open Finance.
abstract class ExclusaoContaRepository {
  /// Lança [ExclusaoContaException] se a conta não puder ser excluída.
  Future<void> excluirConta();
}

class ExclusaoContaException implements Exception {
  const ExclusaoContaException(this.mensagem);

  /// Texto pronto para mostrar ao usuário.
  final String mensagem;

  @override
  String toString() => mensagem;
}
