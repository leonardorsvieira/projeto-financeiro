import 'package:meubolso/features/investimentos/domain/investimento.dart';

/// Tipo de operação de investimento reconhecida pelo ditado.
enum OperacaoInvestimento {
  compra('compra', 'Compra'),
  venda('venda', 'Venda'),
  aporte('aporte', 'Aporte'),
  resgate('resgate', 'Resgate'),
  dividendo('dividendo', 'Dividendo'),
  juros('juros', 'Juros'),
  rendimento('rendimento', 'Rendimento');

  const OperacaoInvestimento(this.dbValue, this.rotulo);

  final String dbValue;
  final String rotulo;

  static OperacaoInvestimento fromDb(String dbValue) =>
      OperacaoInvestimento.values.firstWhere(
        (t) => t.dbValue == dbValue,
        orElse: () => OperacaoInvestimento.compra,
      );
}

/// Rascunho de investimento reconhecido por voz.
class RascunhoInvestimento {
  const RascunhoInvestimento({
    this.classe,
    this.nome,
    this.operacao,
    this.quantidade,
    this.precoUnitarioReais,
    this.valorReais,
    this.dataIso,
  });

  final String? classe; // acao, fii, cripto, renda_fixa, banco_digital
  final String? nome; // ex.: PETR4, CDB, Nubank
  final String? operacao; // compra, venda, aporte, resgate, dividendo, juros, rendimento
  final String? quantidade; // string numérica ex.: "10" ou "10,5"
  final String? precoUnitarioReais; // preço unitário ex.: "38,50"
  final String? valorReais; // valor total (para aporte/resgate/dividendo)
  final String? dataIso; // AAAA-MM-DD

  /// Converte quantidade para double.
  double? get quantidadeDouble {
    if (quantidade == null) return null;
    final v = quantidade!.replaceAll(',', '.');
    return double.tryParse(v);
  }

  /// Converte preço unitário para centavos.
  int? get precoUnitCents {
    if (precoUnitarioReais == null) return null;
    final v = precoUnitarioReais!.replaceAll(',', '.');
    final d = double.tryParse(v);
    if (d == null) return null;
    return (d * 100).round();
  }

  /// Converte valor total para centavos.
  int? get valorCents {
    if (valorReais == null) return null;
    final v = valorReais!.replaceAll(',', '.');
    final d = double.tryParse(v);
    if (d == null) return null;
    return (d * 100).round();
  }

  /// Mapeia classe string para TipoClasseInvestimento.
  TipoClasseInvestimento? get classeEnum {
    if (classe == null) return null;
    try {
      return TipoClasseInvestimento.values.firstWhere(
        (c) => c.dbValue == classe,
      );
    } catch (_) {
      return null;
    }
  }

  /// Mapeia operacao string para OperacaoInvestimento.
  OperacaoInvestimento? get operacaoEnum {
    if (operacao == null) return null;
    try {
      return OperacaoInvestimento.fromDb(operacao!);
    } catch (_) {
      return null;
    }
  }

  /// Verifica se é operação por quantidade (ações, FIIs, cripto).
  bool get ePorQuantidade =>
      classeEnum?.ePorQuantidade ?? false;

  factory RascunhoInvestimento.fromJson(Map<String, dynamic> json) {
    String? texto(String chave) {
      final v = json[chave];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    return RascunhoInvestimento(
      classe: texto('investimento_classe'),
      nome: texto('investimento_nome'),
      operacao: texto('operacao'),
      quantidade: texto('quantidade'),
      precoUnitarioReais: texto('preco_unitario'),
      valorReais: texto('valor'),
      dataIso: texto('data'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (classe != null) 'investimento_classe': classe,
        if (nome != null) 'investimento_nome': nome,
        if (operacao != null) 'operacao': operacao,
        if (quantidade != null) 'quantidade': quantidade,
        if (precoUnitarioReais != null) 'preco_unitario': precoUnitarioReais,
        if (valorReais != null) 'valor': valorReais,
        if (dataIso != null) 'data': dataIso,
      };
}