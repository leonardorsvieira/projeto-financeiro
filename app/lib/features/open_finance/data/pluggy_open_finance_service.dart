import '../domain/conta_bancaria_conectada.dart';
import '../domain/transacao_bancaria_importada.dart';

class BancoDisponivelOpenFinance {
  const BancoDisponivelOpenFinance({
    required this.nome,
    required this.corHex,
    required this.logoSvgPath,
    this.tiposSuportados = const ['Conta Corrente', 'Cartão de Crédito', 'Pix'],
  });

  final String nome;
  final String corHex;
  final String logoSvgPath;
  final List<String> tiposSuportados;
}

class PluggyOpenFinanceService {
  PluggyOpenFinanceService();

  static const List<BancoDisponivelOpenFinance> bancosPrincipais = [
    BancoDisponivelOpenFinance(
      nome: 'Nubank',
      corHex: '#8A05BE',
      logoSvgPath: 'assets/bancos/nubank.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'Banco Inter',
      corHex: '#FF7A00',
      logoSvgPath: 'assets/bancos/inter.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'Itaú Unibanco',
      corHex: '#EC7000',
      logoSvgPath: 'assets/bancos/itau.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'Bradesco',
      corHex: '#CC092F',
      logoSvgPath: 'assets/bancos/bradesco.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'Santander',
      corHex: '#EA1D2C',
      logoSvgPath: 'assets/bancos/santander.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'C6 Bank',
      corHex: '#242424',
      logoSvgPath: 'assets/bancos/c6.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'PicPay',
      corHex: '#21C25E',
      logoSvgPath: 'assets/bancos/picpay.png',
    ),
    BancoDisponivelOpenFinance(
      nome: 'Mercado Pago',
      corHex: '#00A8F3',
      logoSvgPath: 'assets/bancos/mercadopago.png',
    ),
  ];

  /// Simula ou executa a conexão Open Finance com o banco selecionado.
  Future<ContaBancariaConectada> conectarBanco({
    required String nomeBanco,
    required String tipoConta,
    String? corHex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final id = 'banco_${DateTime.now().millisecondsSinceEpoch}';
    final cor = corHex ??
        (bancosPrincipais
            .firstWhere((b) => b.nome.contains(nomeBanco),
                orElse: () => bancosPrincipais.first)
            .corHex);

    return ContaBancariaConectada(
      id: id,
      nomeBanco: nomeBanco,
      tipoConta: tipoConta,
      corHex: cor,
      ultimoSync: DateTime.now(),
      status: StatusConexaoBanco.conectado,
      itemIdPluggy: 'pluggy_item_$id',
    );
  }

  /// Puxa transações recentes da conta conectada via Open Finance.
  Future<List<TransacaoBancariaImportada>> buscarTransacoesRecentes(
    ContaBancariaConectada conta,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final agora = DateTime.now();

    return [
      TransacaoBancariaImportada(
        id: 'of_${conta.id}_1',
        nomeBanco: conta.nomeBanco,
        descricao: 'Supermercado e Feira',
        valorCents: 14590,
        isReceita: false,
        formaPagamento: 'Cartão: ${conta.nomeBanco}',
        data: agora.subtract(const Duration(hours: 3)),
        origem: OrigemTransacaoBancaria.openFinance,
        categoriaSugerida: 'Alimentação',
        estabelecimento: 'Supermercado Exemplo',
      ),
      TransacaoBancariaImportada(
        id: 'of_${conta.id}_2',
        nomeBanco: conta.nomeBanco,
        descricao: 'Transferência Pix',
        valorCents: 5000,
        isReceita: false,
        formaPagamento: 'Pix',
        data: agora.subtract(const Duration(days: 1)),
        origem: OrigemTransacaoBancaria.openFinance,
        categoriaSugerida: 'Outros',
        estabelecimento: 'Pix - Fornecedor',
      ),
    ];
  }
}
