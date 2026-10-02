import 'acesso.dart';
import 'regras_acesso.dart';

abstract class AcessoRepository {
  /// Status da conta logada. Erros sobem: quem decide o que fazer é o provider.
  Future<StatusAcesso> status();

  /// Lista de acessos, ordenada por e-mail (só administrador enxerga todos).
  Future<List<Acesso>> listar();

  /// Cria ou atualiza o acesso do [email] (upsert pelo e-mail).
  Future<void> salvar(String email, DateTime? validoAte, String? observacao);

  /// Soma [dias] à maior data entre hoje e a validade atual.
  Future<void> renovar(String email, {int dias = diasRenovacao});

  /// Bloqueia na hora: validade = ontem.
  Future<void> bloquear(String email);

  Future<void> remover(String email);
}

class AcessoException implements Exception {
  const AcessoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
