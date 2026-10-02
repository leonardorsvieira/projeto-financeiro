import 'regras_acesso.dart';

/// Situação de acesso da conta logada, como o servidor decidiu.
class StatusAcesso {
  const StatusAcesso({
    required this.ativo,
    required this.admin,
    this.validoAte,
  });

  /// `public.acesso_ativo()`: administrador ou e-mail com validade em dia.
  final bool ativo;

  /// A conta está em `administradores`.
  final bool admin;

  /// Data (sem hora) da própria linha em `acessos`; null = sem linha ou sem prazo.
  final DateTime? validoAte;

  bool get liberado => ativo || admin;

  @override
  bool operator ==(Object other) =>
      other is StatusAcesso &&
      other.ativo == ativo &&
      other.admin == admin &&
      other.validoAte == validoAte;

  @override
  int get hashCode => Object.hash(ativo, admin, validoAte);
}

/// Uma linha da tabela `acessos` (e-mail liberado pelo dono).
class Acesso {
  const Acesso({
    required this.email,
    this.validoAte,
    this.observacao,
    this.atualizadoEm,
  });

  final String email;

  /// null = sem prazo.
  final DateTime? validoAte;
  final String? observacao;
  final DateTime? atualizadoEm;

  factory Acesso.fromMap(Map<String, dynamic> m) {
    final validade = m['valido_ate'];
    final obs = m['observacao'] as String?;
    final atualizado = m['atualizado_em'];
    return Acesso(
      email: m['email'] as String,
      validoAte: validade is String ? soData(DateTime.parse(validade)) : null,
      observacao: (obs == null || obs.trim().isEmpty) ? null : obs,
      atualizadoEm: atualizado is String ? DateTime.tryParse(atualizado) : null,
    );
  }
}
