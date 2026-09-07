/// Tipo de rendimento recebido de um investimento.
enum TipoRendimentoInvestimento {
  dividendo('dividendo', 'Dividendo'),
  juros('juros', 'Juros'),
  rendimento('rendimento', 'Rendimento'),
  outro('outro', 'Outro');

  const TipoRendimentoInvestimento(this.dbValue, this.rotulo);

  final String dbValue;
  final String rotulo;

  static TipoRendimentoInvestimento fromDb(String dbValue) =>
      TipoRendimentoInvestimento.values.firstWhere(
        (t) => t.dbValue == dbValue,
        orElse: () => TipoRendimentoInvestimento.rendimento,
      );
}

/// Rendimento (dividendo/juros/etc.) recebido de um investimento.
class RendimentoInvestimento {
  const RendimentoInvestimento({
    required this.id,
    required this.investimentoId,
    required this.tipo,
    required this.valorCents,
    required this.data,
  });

  final String id;
  final String investimentoId;
  final TipoRendimentoInvestimento tipo;
  final int valorCents;
  final DateTime data;

  RendimentoInvestimento copyWith({
    String? id,
    String? investimentoId,
    TipoRendimentoInvestimento? tipo,
    int? valorCents,
    DateTime? data,
  }) {
    return RendimentoInvestimento(
      id: id ?? this.id,
      investimentoId: investimentoId ?? this.investimentoId,
      tipo: tipo ?? this.tipo,
      valorCents: valorCents ?? this.valorCents,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investimento_id': investimentoId,
      'tipo': tipo.dbValue,
      'valor_cents': valorCents,
      'data': _isoDate(data),
    };
  }

  factory RendimentoInvestimento.fromMap(Map<String, dynamic> map) {
    return RendimentoInvestimento(
      id: map['id'] as String,
      investimentoId: map['investimento_id'] as String,
      tipo: TipoRendimentoInvestimento.fromDb(map['tipo'] as String),
      valorCents: ((map['valor_cents'] as num?) ?? 0).toInt(),
      data: DateTime.parse(map['data'] as String),
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}