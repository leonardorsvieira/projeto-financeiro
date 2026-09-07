import 'dart:convert';

enum CampoDitado {
  descricao('descricao'),
  valor('valor'),
  categoria('categoria'),
  formaPagamento('forma_pagamento'),
  data('data'),
  vencimento('vencimento'),
  itens('itens'),
  tipo('tipo');

  const CampoDitado(this.chaveJson);

  final String chaveJson;
}

class RascunhoItem {
  const RascunhoItem({
    required this.descricao,
    this.valorReais,
  });

  final String descricao;
  final String? valorReais;

  int? get valorCents {
    if (valorReais == null) return null;
    final v = valorReais!.replaceAll(',', '.');
    final d = double.tryParse(v);
    if (d == null) return null;
    return (d * 100).round();
  }

  factory RascunhoItem.fromJson(Map<String, dynamic> json) {
    return RascunhoItem(
      descricao: json['descricao'] as String,
      valorReais: json['valor_reais'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'valor_reais': valorReais,
      };
}

class RascunhoLancamento {
  const RascunhoLancamento({
    this.descricao,
    this.valorTexto,
    this.categoria,
    this.formaPagamento,
    this.dataIso,
    this.vencimentoIso,
    this.itens,
    this.tipo,
  });

  final String? descricao;
  final String? valorTexto;
  final String? categoria;
  final String? formaPagamento;
  final String? dataIso;
  final String? vencimentoIso;
  final List<RascunhoItem>? itens;
  final String? tipo;

  factory RascunhoLancamento.fromJson(Map<String, dynamic> json) {
    String? texto(String chave) {
      final v = json[chave];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    List<RascunhoItem>? parseItens(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map(RascunhoItem.fromJson)
            .toList();
      }
      return null;
    }

    return RascunhoLancamento(
      descricao: texto('descricao'),
      valorTexto: texto('valor_reais'),
      categoria: texto('categoria'),
      formaPagamento: texto('forma_pagamento'),
      dataIso: texto('data'),
      vencimentoIso: texto('vencimento'),
      itens: parseItens(json['itens']),
      tipo: texto('tipo'),
    );
  }

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'valor_reais': valorTexto,
        'categoria': categoria,
        'forma_pagamento': formaPagamento,
        'data': dataIso,
        'vencimento': vencimentoIso,
        if (itens != null && itens!.isNotEmpty)
          'itens': itens!.map((e) => e.toJson()).toList(),
        'tipo': tipo,
      };

  RascunhoLancamento corrigir(CampoDitado campo, String? valor) {
    switch (campo) {
      case CampoDitado.descricao:
        return RascunhoLancamento(
          descricao: valor,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.valor:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valor,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.categoria:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: valor,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.formaPagamento:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: valor,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.data:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: valor,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.vencimento:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: valor,
          itens: itens,
          tipo: tipo,
        );
      case CampoDitado.itens:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: valor != null
              ? (json.decode(valor) as List)
                  .map((e) => RascunhoItem.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
          tipo: tipo,
        );
      case CampoDitado.tipo:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
          itens: itens,
          tipo: valor,
        );
    }
  }
}