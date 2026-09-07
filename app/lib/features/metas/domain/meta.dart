class Meta {
  const Meta({
    required this.id,
    required this.categoria,
    required this.valorLimiteCents,
  });

  final String id;
  final String categoria;
  final int valorLimiteCents;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'valor_limite_cents': valorLimiteCents,
    };
  }

  factory Meta.fromMap(Map<String, dynamic> map) {
    return Meta(
      id: map['id'] as String,
      categoria: map['categoria'] as String,
      valorLimiteCents: (map['valor_limite_cents'] as num).toInt(),
    );
  }
}