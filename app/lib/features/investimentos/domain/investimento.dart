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

  static TipoClasseInvestimento fromDb(String dbValue) => TipoClasseInvestimento
      .values.firstWhere((c) => c.dbValue == dbValue,
          orElse: () => TipoClasseInvestimento.acao);
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
  });

  final String id;
  final TipoClasseInvestimento classe;
  final String nome;
  final double quantidade;
  final int precoAtualCents;
  final int saldoCents;

  bool get ePorQuantidade => classe.ePorQuantidade;

  /// Patrimônio: quantidade × preço (por quantidade) ou saldo (por saldo).
  int get patrimonioCents {
    if (ePorQuantidade) {
      return (quantidade * precoAtualCents).round();
    }
    return saldoCents;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classe': classe.dbValue,
      'nome': nome,
      'quantidade': quantidade,
      'preco_atual_cents': precoAtualCents,
      'saldo_cents': saldoCents,
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
    );
  }
}
