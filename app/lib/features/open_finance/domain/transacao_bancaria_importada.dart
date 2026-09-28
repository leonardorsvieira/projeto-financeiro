/// Origem da captura da transação bancária.
enum OrigemTransacaoBancaria {
  openFinance('open_finance', 'Open Finance'),
  notificacaoPush('notificacao_push', 'Notificação do Banco'),
  arquivoOfx('arquivo_ofx', 'Extrato OFX');

  const OrigemTransacaoBancaria(this.dbValue, this.rotulo);

  final String dbValue;
  final String rotulo;

  static OrigemTransacaoBancaria fromDb(String dbValue) =>
      OrigemTransacaoBancaria.values.firstWhere(
        (o) => o.dbValue == dbValue,
        orElse: () => OrigemTransacaoBancaria.openFinance,
      );
}

/// Representa uma transação bancária crua capturada via Open Finance / Push / OFX.
class TransacaoBancariaImportada {
  const TransacaoBancariaImportada({
    required this.id,
    required this.nomeBanco,
    required this.descricao,
    required this.valorCents,
    required this.isReceita,
    required this.formaPagamento, // ex: "Pix", "Cartão: Nubank"
    required this.data,
    required this.origem,
    this.categoriaSugerida = 'Outros',
    this.estabelecimento,
  });

  final String id;
  final String nomeBanco;
  final String descricao;
  final int valorCents;
  final bool isReceita;
  final String formaPagamento;
  final DateTime data;
  final OrigemTransacaoBancaria origem;
  final String categoriaSugerida;
  final String? estabelecimento;

  double get valorReais => valorCents / 100.0;
}
