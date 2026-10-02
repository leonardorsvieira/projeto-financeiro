import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/domain/acesso_repository.dart';
import 'package:meubolso/features/acesso/domain/regras_acesso.dart';

/// Repositório de acessos em memória. Padrão: conta ativa e não administradora,
/// para que os testes que não tratam de acesso passem pelo portão sem mudança.
class FakeAcessoRepository implements AcessoRepository {
  FakeAcessoRepository({
    this.statusAtual = const StatusAcesso(ativo: true, admin: false),
    List<Acesso> acessos = const [],
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    for (final a in acessos) {
      _porEmail[a.email] = a;
    }
  }

  /// Devolvido por [status] (a menos que [erroStatus] esteja definido).
  StatusAcesso statusAtual;

  /// Se definido, [status] lança.
  Object? erroStatus;

  /// Se definido, as operações de lista/escrita lançam.
  Object? erroOperacao;

  int statusChamadas = 0;

  final DateTime Function() _agora;
  final Map<String, Acesso> _porEmail = {};

  /// Acessos ordenados por e-mail.
  List<Acesso> get acessos =>
      (_porEmail.values.toList()..sort((a, b) => a.email.compareTo(b.email)));

  @override
  Future<StatusAcesso> status() async {
    statusChamadas++;
    if (erroStatus != null) throw erroStatus!;
    return statusAtual;
  }

  @override
  Future<List<Acesso>> listar() async {
    if (erroOperacao != null) throw erroOperacao!;
    return acessos;
  }

  @override
  Future<void> salvar(
    String email,
    DateTime? validoAte,
    String? observacao,
  ) async {
    if (erroOperacao != null) throw erroOperacao!;
    final chave = normalizarEmail(email);
    if (!emailValido(chave)) {
      throw const AcessoException('Informe um e-mail válido.');
    }
    final obs = observacao?.trim();
    _porEmail[chave] = Acesso(
      email: chave,
      validoAte: validoAte == null ? null : soData(validoAte),
      observacao: (obs == null || obs.isEmpty) ? null : obs,
      atualizadoEm: _agora().toUtc(),
    );
  }

  Acesso _existente(String email) {
    final atual = _porEmail[normalizarEmail(email)];
    if (atual == null) {
      throw const AcessoException('Este e-mail não está na lista.');
    }
    return atual;
  }

  @override
  Future<void> renovar(String email, {int dias = diasRenovacao}) async {
    if (erroOperacao != null) throw erroOperacao!;
    final atual = _existente(email);
    _porEmail[atual.email] = Acesso(
      email: atual.email,
      validoAte: novaValidade(atual.validoAte, _agora(), dias: dias),
      observacao: atual.observacao,
      atualizadoEm: _agora().toUtc(),
    );
  }

  @override
  Future<void> bloquear(String email) async {
    if (erroOperacao != null) throw erroOperacao!;
    final atual = _existente(email);
    _porEmail[atual.email] = Acesso(
      email: atual.email,
      validoAte: validadeDeBloqueio(_agora()),
      observacao: atual.observacao,
      atualizadoEm: _agora().toUtc(),
    );
  }

  @override
  Future<void> remover(String email) async {
    if (erroOperacao != null) throw erroOperacao!;
    final atual = _existente(email);
    _porEmail.remove(atual.email);
  }
}
