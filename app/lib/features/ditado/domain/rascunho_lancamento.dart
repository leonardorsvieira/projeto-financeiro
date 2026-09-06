enum CampoDitado {
  descricao('descricao'),
  valor('valor'),
  categoria('categoria'),
  formaPagamento('forma_pagamento'),
  data('data'),
  vencimento('vencimento');

  const CampoDitado(this.chaveJson);

  final String chaveJson;
}

class RascunhoLancamento {
  const RascunhoLancamento({
    this.descricao,
    this.valorTexto,
    this.categoria,
    this.formaPagamento,
    this.dataIso,
    this.vencimentoIso,
  });

  final String? descricao;
  final String? valorTexto;
  final String? categoria;
  final String? formaPagamento;
  final String? dataIso;
  final String? vencimentoIso;

  factory RascunhoLancamento.fromJson(Map<String, dynamic> json) {
    String? texto(String chave) {
      final v = json[chave];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    return RascunhoLancamento(
      descricao: texto('descricao'),
      valorTexto: texto('valor_reais'),
      categoria: texto('categoria'),
      formaPagamento: texto('forma_pagamento'),
      dataIso: texto('data'),
      vencimentoIso: texto('vencimento'),
    );
  }

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'valor_reais': valorTexto,
        'categoria': categoria,
        'forma_pagamento': formaPagamento,
        'data': dataIso,
        'vencimento': vencimentoIso,
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
        );
      case CampoDitado.valor:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valor,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
        );
      case CampoDitado.categoria:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: valor,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
        );
      case CampoDitado.formaPagamento:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: valor,
          dataIso: dataIso,
          vencimentoIso: vencimentoIso,
        );
      case CampoDitado.data:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: valor,
          vencimentoIso: vencimentoIso,
        );
      case CampoDitado.vencimento:
        return RascunhoLancamento(
          descricao: descricao,
          valorTexto: valorTexto,
          categoria: categoria,
          formaPagamento: formaPagamento,
          dataIso: dataIso,
          vencimentoIso: valor,
        );
    }
  }
}