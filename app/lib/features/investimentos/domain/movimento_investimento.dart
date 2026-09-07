/// Tipo de operação de um movimento de investimento.
enum TipoMovimentoInvestimento {
  compra('compra', 'Compra'),
  venda('venda', 'Venda');

  const TipoMovimentoInvestimento(this.dbValue, this.rotulo);

  final String dbValue;
  final String rotulo;

  static TipoMovimentoInvestimento fromDb(String dbValue) =>
      TipoMovimentoInvestimento.values.firstWhere(
        (t) => t.dbValue == dbValue,
        orElse: () => TipoMovimentoInvestimento.compra,
      );
}

/// Registro de compra/venda (ou aporte/resgate para RF e banco digital).
class MovimentoInvestimento {
  const MovimentoInvestimento({
    required this.id,
    required this.investimentoId,
    required this.tipo,
    required this.quantidade,
    required this.precoUnitCents,
    required this.data,
  });

  final String id;
  final String investimentoId;
  final TipoMovimentoInvestimento tipo;
  final double quantidade;
  final int precoUnitCents;
  final DateTime data;

  /// Valor financeiro do movimento (qtd × preço por quantidade; preço para
  /// RF/bco, onde quantidade é 1).
  int get valorCents =>
      (quantidade * precoUnitCents).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investimento_id': investimentoId,
      'tipo': tipo.dbValue,
      'quantidade': quantidade,
      'preco_unit_cents': precoUnitCents,
      'data': _isoDate(data),
    };
  }

  factory MovimentoInvestimento.fromMap(Map<String, dynamic> map) {
    return MovimentoInvestimento(
      id: map['id'] as String,
      investimentoId: map['investimento_id'] as String,
      tipo: TipoMovimentoInvestimento.fromDb(map['tipo'] as String),
      quantidade: ((map['quantidade'] as num?) ?? 0).toDouble(),
      precoUnitCents: ((map['preco_unit_cents'] as num?) ?? 0).toInt(),
      data: DateTime.parse(map['data'] as String),
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
