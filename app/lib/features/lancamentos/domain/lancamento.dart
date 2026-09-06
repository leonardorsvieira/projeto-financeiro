class Lancamento {
  const Lancamento({
    required this.id,
    required this.descricao,
    required this.valorCents,
    required this.categoria,
    required this.formaPagamento,
    required this.data,
    this.vencimento,
    this.obs,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String descricao;
  final int valorCents;
  final String categoria;
  final String formaPagamento;
  final DateTime data;
  final DateTime? vencimento;
  final String? obs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lancamento copyWith({
    String? descricao,
    int? valorCents,
    String? categoria,
    String? formaPagamento,
    DateTime? data,
    DateTime? Function()? vencimento,
    String? Function()? obs,
  }) {
    return Lancamento(
      id: id,
      descricao: descricao ?? this.descricao,
      valorCents: valorCents ?? this.valorCents,
      categoria: categoria ?? this.categoria,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      data: data ?? this.data,
      vencimento: vencimento != null ? vencimento() : this.vencimento,
      obs: obs != null ? obs() : this.obs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor_cents': valorCents,
      'categoria': categoria,
      'forma_pagamento': formaPagamento,
      'data': data.toIso8601String().substring(0, 10),
      'vencimento': vencimento?.toIso8601String().substring(0, 10),
      'obs': obs,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Lancamento.fromMap(Map<String, dynamic> map) {
    return Lancamento(
      id: map['id'] as String,
      descricao: map['descricao'] as String,
      valorCents: (map['valor_cents'] as num).toInt(),
      categoria: map['categoria'] as String,
      formaPagamento: map['forma_pagamento'] as String,
      data: DateTime.parse(map['data'] as String),
      vencimento: map['vencimento'] != null
          ? DateTime.parse(map['vencimento'] as String)
          : null,
      obs: map['obs'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}