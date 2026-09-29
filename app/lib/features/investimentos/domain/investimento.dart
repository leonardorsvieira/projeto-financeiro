/// Classe de um ativo de investimento, com flag de como é precificado.
enum TipoClasseInvestimento {
  acao('acao', 'Ações', true),
  fii('fii', 'FIIs', true),
  cripto('cripto', 'Cripto', true),
  rendaFixa('renda_fixa', 'Renda Fixa', false),
  bancoDigital('banco_digital', 'Banco Digital', false);

  const TipoClasseInvestimento(this.dbValue, this.rotulo, this.ePorQuantidade);

  final String dbValue;
  final String rotulo;

  /// true → posição = quantidade × preço; false → posição = saldo.
  final bool ePorQuantidade;

  static TipoClasseInvestimento fromDb(String dbValue) =>
      TipoClasseInvestimento.values.firstWhere(
        (c) => c.dbValue == dbValue,
        orElse: () => TipoClasseInvestimento.acao,
      );
}

/// Posição/ativo de investimento nas 4 classes.
class Investimento {
  const Investimento({
    required this.id,
    required this.classe,
    required this.nome,
    this.quantidade = 0,
    this.precoAtualCents = 0,
    this.saldoCents = 0,
    this.pluggyId,
    this.valorInvestidoCents,
  });

  final String id;
  final TipoClasseInvestimento classe;
  final String nome;
  final double quantidade;
  final int precoAtualCents;
  final int saldoCents;

  /// Id do investimento na Pluggy quando veio do Open Finance (null = manual).
  /// A sincronização sobrescreve esses ativos com a posição do banco.
  final String? pluggyId;

  /// Quanto foi aplicado (informado pelo banco via Open Finance); null quando
  /// o banco não informa — aí não dá para calcular o rendimento.
  final int? valorInvestidoCents;

  bool get importadoOpenFinance => pluggyId != null;

  bool get ePorQuantidade => classe.ePorQuantidade;

  /// Patrimônio: quantidade × preço (por quantidade) ou saldo (por saldo).
  int get patrimonioCents {
    if (ePorQuantidade) {
      return (quantidade * precoAtualCents).round();
    }
    return saldoCents;
  }

  /// Quanto rendeu (negativo = perda): valor atual − valor aplicado.
  int? get rendimentoCents => valorInvestidoCents == null
      ? null
      : patrimonioCents - valorInvestidoCents!;

  /// Rendimento em % sobre o valor aplicado.
  double? get rentabilidadePercent {
    final investido = valorInvestidoCents;
    if (investido == null || investido == 0) return null;
    return (patrimonioCents - investido) / investido * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classe': classe.dbValue,
      'nome': nome,
      'quantidade': quantidade,
      'preco_atual_cents': precoAtualCents,
      'saldo_cents': saldoCents,
      if (pluggyId != null) 'pluggy_id': pluggyId,
      if (valorInvestidoCents != null)
        'valor_investido_cents': valorInvestidoCents,
    };
  }

  factory Investimento.fromMap(Map<String, dynamic> map) {
    return Investimento(
      id: map['id'] as String,
      classe: TipoClasseInvestimento.fromDb(map['classe'] as String),
      nome: map['nome'] as String,
      quantidade: ((map['quantidade'] as num?) ?? 0).toDouble(),
      precoAtualCents: ((map['preco_atual_cents'] as num?) ?? 0).toInt(),
      saldoCents: ((map['saldo_cents'] as num?) ?? 0).toInt(),
      pluggyId: map['pluggy_id'] as String?,
      valorInvestidoCents: (map['valor_investido_cents'] as num?)?.toInt(),
    );
  }
}
