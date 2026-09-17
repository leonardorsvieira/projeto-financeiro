class CartaoCredito {
  const CartaoCredito({
    required this.id,
    required this.nome,
    required this.diaFechamento,
    required this.diaVencimento,
    this.validadeMMYY,
    this.limiteCents,
    this.corHex = '#0B7A4B',
  });

  final String id;
  final String nome;
  final int diaFechamento;
  final int diaVencimento;
  final String? validadeMMYY;
  final int? limiteCents;
  final String corHex;

  CartaoCredito copyWith({
    String? nome,
    int? diaFechamento,
    int? diaVencimento,
    String? Function()? validadeMMYY,
    int? Function()? limiteCents,
    String? corHex,
  }) {
    return CartaoCredito(
      id: id,
      nome: nome ?? this.nome,
      diaFechamento: diaFechamento ?? this.diaFechamento,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      validadeMMYY: validadeMMYY != null ? validadeMMYY() : this.validadeMMYY,
      limiteCents: limiteCents != null ? limiteCents() : this.limiteCents,
      corHex: corHex ?? this.corHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dia_fechamento': diaFechamento,
      'dia_vencimento': diaVencimento,
      'validade_mmyy': validadeMMYY,
      'limite_cents': limiteCents,
      'cor_hex': corHex,
    };
  }

  factory CartaoCredito.fromMap(Map<String, dynamic> map) {
    return CartaoCredito(
      id: map['id'] as String,
      nome: map['nome'] as String,
      diaFechamento: (map['dia_fechamento'] as num).toInt(),
      diaVencimento: (map['dia_vencimento'] as num).toInt(),
      validadeMMYY: map['validade_mmyy'] as String?,
      limiteCents: map['limite_cents'] != null
          ? (map['limite_cents'] as num).toInt()
          : null,
      corHex: map['cor_hex'] as String? ?? '#0B7A4B',
    );
  }
}
