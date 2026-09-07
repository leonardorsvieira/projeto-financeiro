class LancamentoItem {
  const LancamentoItem({
    required this.descricao,
    required this.valorCents,
  });

  final String descricao;
  final int valorCents;

  Map<String, dynamic> toMap() => {
        'descricao': descricao,
        'valor_cents': valorCents,
      };

  factory LancamentoItem.fromMap(Map<String, dynamic> map) {
    return LancamentoItem(
      descricao: map['descricao'] as String,
      valorCents: (map['valor_cents'] as num).toInt(),
    );
  }
}

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
    this.itens,
    this.fixoMensal = false,
    this.serieId,
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
  final List<LancamentoItem>? itens;
  final bool fixoMensal;
  final String? serieId;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get somaItens {
    if (itens == null) return 0;
    return itens!.fold(0, (s, i) => s + i.valorCents);
  }

  bool get temItens => itens != null && itens!.isNotEmpty;

  Lancamento copyWith({
    String? descricao,
    int? valorCents,
    String? categoria,
    String? formaPagamento,
    DateTime? data,
    DateTime? Function()? vencimento,
    String? Function()? obs,
    List<LancamentoItem>? Function()? itens,
    bool? fixoMensal,
    String? Function()? serieId,
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
      itens: itens != null ? itens() : this.itens,
      fixoMensal: fixoMensal ?? this.fixoMensal,
      serieId: serieId != null ? serieId() : this.serieId,
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
      'itens': itens?.map((e) => e.toMap()).toList(),
      'fixo_mensal': fixoMensal,
      'serie_id': serieId,
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
      itens: (map['itens'] as List<dynamic>?)
          ?.map((e) => LancamentoItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      fixoMensal: map['fixo_mensal'] as bool? ?? false,
      serieId: map['serie_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}