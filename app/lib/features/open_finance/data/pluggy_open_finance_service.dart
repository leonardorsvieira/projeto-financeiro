import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/edge_function.dart';
import '../../investimentos/domain/investimento.dart';
import '../../lancamentos/domain/lancamento.dart'
    show categoriaMovimentacaoInvestimento, categoriaTransferenciaEntreContas;
import '../domain/conta_bancaria_conectada.dart';
import '../domain/transacao_bancaria_importada.dart';

class BancoDisponivelOpenFinance {
  const BancoDisponivelOpenFinance({
    required this.nome,
    required this.corHex,
    required this.logoSvgPath,
    this.connectorId,
    this.tiposSuportados = const ['Conta Corrente', 'Cartão de Crédito', 'Pix'],
  });

  final String nome;
  final String corHex;
  final String logoSvgPath;
  final int? connectorId;
  final List<String> tiposSuportados;
}

/// Sinal do valor na Pluggy: em conta corrente, positivo = entrada; no
/// CARTÃO DE CRÉDITO é o contrário — positivo = compra (saída) e negativo =
/// estorno/crédito na fatura.
bool ehEntrada({required double amount, required bool cartaoDeCredito}) =>
    cartaoDeCredito ? amount < 0 : amount > 0;

/// Pagamento de fatura aparece como saída na conta corrente E como crédito no
/// cartão, enquanto as compras já entram pelo cartão: importar o pagamento
/// contaria o gasto duas vezes.
bool ehPagamentoDeFatura(String? categoria, String descricao) {
  final cat = (categoria ?? '').toLowerCase();
  if (cat.contains('credit card payment') ||
      cat.contains('pagamento de cartão') ||
      cat.contains('pagamento de fatura')) {
    return true;
  }
  final d = descricao.toLowerCase();
  return RegExp(r'pagamento (de |da )?fatura|pagto\.? fatura|'
          r'pagamento recebido|pagamento efetuado|pgto fatura')
      .hasMatch(d);
}

String _soDigitos(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

String _nomeNormalizado(String? s) =>
    (s ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

final _reInvestimento = RegExp(
  r'\b(rdb|cdb|lci|lca|b3)\b|resgate|aplica[cç][aã]o|caixinha|cofrinho|'
  r'porquinho|dinheiro guardado|dinheiro resgatado|nuinvest|tesouro|'
  r'poupan[cç]a|nota bov|bovespa',
);

/// Categoria neutra (não é renda nem gasto) ou null se for movimento real:
/// - investimento: aplicação/resgate (RDB, CDB, caixinha, poupança…);
/// - transferência entre contas do próprio titular: a Pluggy marca como
///   mesma titularidade, ou a contraparte (quem pagou numa entrada, quem
///   recebeu numa saída) tem o CPF — ou, sem CPF, o nome — do titular.
String? categoriaNeutra({
  required String? categoriaPluggy,
  required String descricao,
  required Map<String, dynamic>? paymentData,
  required bool entrada,
  required String? cpfTitular,
  required String? nomeTitular,
}) {
  final cat = (categoriaPluggy ?? '').toLowerCase();
  if (cat.contains('invest') || _reInvestimento.hasMatch(descricao.toLowerCase())) {
    return categoriaMovimentacaoInvestimento;
  }
  if (cat.contains('same person') ||
      cat.contains('same ownership') ||
      cat.contains('mesma titularidade')) {
    return categoriaTransferenciaEntreContas;
  }
  final nome = _nomeNormalizado(nomeTitular);
  // Alguns bancos só trazem a contraparte na descrição:
  // "Transferência Recebida|NOME DA PESSOA".
  final partes = descricao.split('|');
  if (nome.isNotEmpty &&
      partes.length > 1 &&
      _nomeNormalizado(partes.last) == nome) {
    return categoriaTransferenciaEntreContas;
  }
  final contraparte =
      paymentData?[entrada ? 'payer' : 'receiver'] as Map<String, dynamic>?;
  if (contraparte == null) return null;
  final documento = contraparte['documentNumber'];
  final docContraparte = _soDigitos(
    documento is Map ? documento['value'] as String? : documento as String?,
  );
  final cpf = _soDigitos(cpfTitular);
  if (cpf.length == 11 && docContraparte == cpf) {
    return categoriaTransferenciaEntreContas;
  }
  if (docContraparte.isEmpty &&
      nome.isNotEmpty &&
      _nomeNormalizado(contraparte['name'] as String?) == nome) {
    return categoriaTransferenciaEntreContas;
  }
  return null;
}

/// Classe do Patrimônio para um investimento da Pluggy (`type`/`subtype`).
TipoClasseInvestimento classeDoInvestimentoPluggy(String? tipo, String? subtipo) {
  final t = (tipo ?? '').toUpperCase();
  final s = (subtipo ?? '').toUpperCase();
  if (s.contains('CRYPTO')) return TipoClasseInvestimento.cripto;
  if (s.contains('REAL_ESTATE')) return TipoClasseInvestimento.fii;
  if (t == 'EQUITY' || t == 'ETF') return TipoClasseInvestimento.acao;
  // FIXED_INCOME, MUTUAL_FUND, SECURITY (previdência), COE, OTHER.
  return TipoClasseInvestimento.rendaFixa;
}

int _centavos(Object? valor) =>
    (((valor as num?) ?? 0).toDouble() * 100).round().clamp(0, 1 << 52);

/// Converte um investimento da Pluggy em posição do Patrimônio, ou null se já
/// foi resgatado (status TOTAL_WITHDRAWAL ou saldo zerado).
Investimento? investimentoDaPluggy(Map<String, dynamic> inv) {
  final id = inv['id'] as String?;
  final saldoCents = _centavos(inv['balance'] ?? inv['amount']);
  if (id == null ||
      (inv['status'] as String?)?.toUpperCase() == 'TOTAL_WITHDRAWAL' ||
      saldoCents <= 0) {
    return null;
  }
  final classe = classeDoInvestimentoPluggy(
    inv['type'] as String?,
    inv['subtype'] as String?,
  );
  final codigo = (inv['code'] as String?)?.trim() ?? '';
  final nomePluggy = (inv['name'] as String?)?.trim() ?? '';
  if (classe.ePorQuantidade) {
    // O ticker vira o nome: é o que a atualização de cotações procura.
    final nome = codigo.isNotEmpty
        ? codigo
        : (nomePluggy.isNotEmpty ? nomePluggy : 'Ativo');
    final quantidade = ((inv['quantity'] as num?) ?? 0).toDouble();
    final precoCents = _centavos(inv['value']);
    if (quantidade > 0 && precoCents > 0) {
      return Investimento(
        id: '',
        classe: classe,
        nome: nome,
        quantidade: quantidade,
        precoAtualCents: precoCents,
        pluggyId: id,
      );
    }
    // Sem quantidade/preço: registra a posição inteira como 1 unidade.
    return Investimento(
      id: '',
      classe: classe,
      nome: nome,
      quantidade: 1,
      precoAtualCents: saldoCents,
      pluggyId: id,
    );
  }
  final emissor = (inv['issuer'] as String?)?.trim() ?? '';
  var nome = nomePluggy.isNotEmpty ? nomePluggy : (codigo.isNotEmpty ? codigo : 'Investimento');
  if (emissor.isNotEmpty && !nome.toLowerCase().contains(emissor.toLowerCase())) {
    nome = '$nome · $emissor';
  }
  return Investimento(
    id: '',
    classe: classe,
    nome: nome,
    saldoCents: saldoCents,
    pluggyId: id,
  );
}

/// Posições de investimento vindas das conexões Pluggy.
class InvestimentosOpenFinance {
  const InvestimentosOpenFinance({
    required this.investimentos,
    required this.completo,
  });

  final List<Investimento> investimentos;

  /// true se todas as conexões responderam: só então é seguro remover do
  /// Patrimônio os importados que não vieram mais.
  final bool completo;
}

class ConexaoMeuPluggyResult {
  final String itemId;
  final String oauthUrl;

  const ConexaoMeuPluggyResult({
    required this.itemId,
    required this.oauthUrl,
  });
}

/// Acesso à Pluggy através da Edge Function `pluggy`.
///
/// As credenciais da Pluggy ficam só no servidor, e a função só devolve
/// items/contas/transações que pertencem ao usuário logado — a conta Pluggy é
/// compartilhada entre todos os usuários do app.
class PluggyOpenFinanceService {
  final http.Client _httpClient;
  final EdgeFunction _funcao;

  PluggyOpenFinanceService({
    http.Client? httpClient,
    EdgeFunction? funcao,
    List<Duration>? esperasAutorizacao,
  })  : _httpClient = httpClient ?? http.Client(),
        _funcao = funcao ?? EdgeFunction.supabase('pluggy'),
        _esperasAutorizacao = esperasAutorizacao ??
            List.filled(10, const Duration(milliseconds: 1500));

  /// Intervalos de consulta enquanto a Pluggy prepara o link de autorização.
  final List<Duration> _esperasAutorizacao;

  static const int connectorMeuPluggy = 200;

  static const List<BancoDisponivelOpenFinance> bancosPrincipais = [
    BancoDisponivelOpenFinance(
      nome: 'Meu Pluggy (meu.pluggy.ai)',
      corHex: '#EF294B',
      logoSvgPath: 'assets/bancos/pluggy.png',
      connectorId: 200,
    ),
    BancoDisponivelOpenFinance(
      nome: 'Nubank',
      corHex: '#8A05BE',
      logoSvgPath: 'assets/bancos/nubank.png',
      connectorId: 2,
    ),
    BancoDisponivelOpenFinance(
      nome: 'Banco Inter',
      corHex: '#FF7A00',
      logoSvgPath: 'assets/bancos/inter.png',
      connectorId: 0,
    ),
    BancoDisponivelOpenFinance(
      nome: 'Itaú Unibanco',
      corHex: '#EC7000',
      logoSvgPath: 'assets/bancos/itau.png',
      connectorId: 1,
    ),
    BancoDisponivelOpenFinance(
      nome: 'Bradesco',
      corHex: '#CC092F',
      logoSvgPath: 'assets/bancos/bradesco.png',
      connectorId: 4,
    ),
    BancoDisponivelOpenFinance(
      nome: 'Santander',
      corHex: '#EA1D2C',
      logoSvgPath: 'assets/bancos/santander.png',
      connectorId: 3,
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

  /// Repassa `metodo caminho` da API da Pluggy pela Edge Function.
  Future<http.Response> _chamar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
  }) async {
    final cabecalhos = await _funcao.cabecalhos();
    if (cabecalhos == null) {
      throw Exception('Entre na sua conta para usar o Open Finance.');
    }
    final resp = await _httpClient.post(
      _funcao.url,
      headers: cabecalhos,
      body: jsonEncode({
        'metodo': metodo,
        'caminho': caminho,
        'corpo': ?corpo,
      }),
    );
    if (resp.statusCode == 401) {
      throw Exception('Sessão expirada ou e-mail não confirmado. Entre de novo.');
    }
    if (resp.statusCode == 429 && resp.body.contains('limite_diario')) {
      throw Exception('Limite diário do Open Finance atingido. Tente amanhã.');
    }
    return resp;
  }

  /// Indica se o servidor tem as credenciais da Pluggy configuradas.
  Future<bool> verificarConfiguracao() async {
    try {
      final resp = await _chamar('GET', '/status');
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['configurado'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Gera um Connect Token temporário para carregar o widget oficial da Pluggy.
  Future<String> gerarConnectToken({
    int? connectorId,
    String? oauthRedirectUri,
    String? itemId,
  }) async {
    final Map<String, dynamic> options = {};
    if (connectorId != null) {
      options['connectorId'] = connectorId;
    }
    if (oauthRedirectUri != null && oauthRedirectUri.isNotEmpty) {
      options['oauthRedirectUri'] = oauthRedirectUri;
    }

    final resp = await _chamar(
      'POST',
      '/connect_token',
      corpo: {'options': options, 'itemId': ?itemId},
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['accessToken'] as String?;
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    throw Exception(
      'Falha ao gerar Connect Token na Pluggy (Status ${resp.statusCode}).',
    );
  }

  /// Abre a interface oficial de autenticação da Pluggy (Widget Connect) no navegador.
  Future<void> abrirWidgetConexao({
    int? connectorId,
    String? oauthRedirectUri,
  }) async {
    final connectToken = await gerarConnectToken(
      connectorId: connectorId,
      oauthRedirectUri: oauthRedirectUri,
    );
    final url = Uri.parse('https://connect.pluggy.ai/?connect_token=$connectToken');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Inicia a conexão direta com o meu.pluggy.ai via API, retornando a URL direta de autorização OAuth
  /// sem exigir passos redundantes de seleção de conector no widget.
  Future<ConexaoMeuPluggyResult> iniciarConexaoMeuPluggyDireta() async {
    final resp = await _chamar(
      'POST',
      '/items',
      corpo: {
        'connectorId': connectorMeuPluggy,
        'parameters': <String, dynamic>{},
      },
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Não foi possível iniciar a conexão com o meu.pluggy.ai '
        '(Status ${resp.statusCode}).',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final itemId = data['id'] as String;

    // A Pluggy cria o item primeiro e só depois (alguns segundos) publica o
    // link de autorização em `parameter.data`: espera por ele.
    var oauthUrl = _urlAutorizacao(data);
    for (final espera in _esperasAutorizacao) {
      if (oauthUrl != null) break;
      await Future<void>.delayed(espera);
      final atual = await _chamar(
        'GET',
        '/items/${Uri.encodeComponent(itemId)}',
      );
      if (atual.statusCode == 200) {
        oauthUrl = _urlAutorizacao(
          jsonDecode(atual.body) as Map<String, dynamic>,
        );
      }
    }
    if (oauthUrl != null) {
      return ConexaoMeuPluggyResult(itemId: itemId, oauthUrl: oauthUrl);
    }

    // Sem link direto: abre o widget da Pluggy continuando ESTE item, para que
    // a conexão fique registrada no usuário (o app não consegue descobrir
    // items criados do zero pelo widget).
    final token = await gerarConnectToken(itemId: itemId);
    return ConexaoMeuPluggyResult(
      itemId: itemId,
      oauthUrl: 'https://connect.pluggy.ai/?connect_token=$token',
    );
  }

  static String? _urlAutorizacao(Map<String, dynamic> item) {
    final parameter = item['parameter'] as Map<String, dynamic>?;
    final url = parameter?['data'] as String?;
    return (url != null && url.startsWith('https://')) ? url : null;
  }

  /// Busca um item específico da Pluggy pelo seu ID. O servidor só o devolve se
  /// pertencer ao usuário logado.
  Future<ContaBancariaConectada> buscarItemPorId(String itemId) async {
    final resp = await _chamar(
      'GET',
      '/items/${Uri.encodeComponent(itemId)}',
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Item não localizado na Pluggy (Status ${resp.statusCode}). Verifique o ID fornecido.',
      );
    }

    final item = jsonDecode(resp.body) as Map<String, dynamic>;
    return _mapearItem(item, nomePadrao: 'Banco Conectado');
  }

  Future<ContaBancariaConectada> _mapearItem(
    Map<String, dynamic> item, {
    String nomePadrao = 'Banco',
  }) async {
    final itemId = item['id'] as String;
    final connector = item['connector'] as Map<String, dynamic>? ?? {};
    var nomeBanco = connector['name'] as String? ?? nomePadrao;
    // No Meu Pluggy o conector se chama "MeuPluggy"; o banco de verdade vem
    // no nome das contas.
    final ehAgregador = connector['id'] == connectorMeuPluggy ||
        nomeBanco.toLowerCase().contains('pluggy');
    final corHex = connector['primaryColor'] as String? ?? '#8A05BE';
    final statusRaw = (item['status'] as String? ?? '').toUpperCase();

    StatusConexaoBanco status;
    if (statusRaw == 'UPDATED' || statusRaw == 'SUCCESS') {
      status = StatusConexaoBanco.conectado;
    } else if (statusRaw == 'UPDATING') {
      status = StatusConexaoBanco.sincronizando;
    } else if (statusRaw == 'LOGIN_ERROR' ||
        statusRaw == 'WAITING_USER_INPUT') {
      status = StatusConexaoBanco.requerReautenticacao;
    } else {
      status = StatusConexaoBanco.conectado;
    }

    final lastSyncStr = item['lastUpdatedAt'] as String?;
    final lastSync = lastSyncStr != null
        ? DateTime.tryParse(lastSyncStr)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    // Busca dados das contas associadas a este item para obter tipo e máscara
    String tipoConta = 'Conta & Cartão';
    String? mascara;

    try {
      final accResp = await _chamar(
        'GET',
        '/accounts?itemId=${Uri.encodeQueryComponent(itemId)}',
      );
      if (accResp.statusCode == 200) {
        final accData = jsonDecode(accResp.body) as Map<String, dynamic>;
        final accounts = (accData['results'] as List<dynamic>?) ?? [];
        _contasPorItem[itemId] = accounts;
        if (accounts.isNotEmpty) {
          final accList = accounts.cast<Map<String, dynamic>>();
          if (ehAgregador) {
            final nomes = accList
                .map((a) => ((a['marketingName'] ?? a['name']) as String?)
                    ?.trim())
                .whereType<String>()
                .where((n) => n.isNotEmpty)
                .toSet();
            if (nomes.isNotEmpty) nomeBanco = nomes.join(' / ');
          }
          final tipos = accList
              .map((a) => (a['type'] as String? ?? 'BANK') == 'CREDIT'
                  ? 'Cartão'
                  : 'Conta')
              .toSet()
              .toList();
          tipoConta = tipos.join(' & ');

          final firstWithNumber = accList.firstWhere(
            (a) => a['number'] != null && a['number'].toString().isNotEmpty,
            orElse: () => {},
          );
          if (firstWithNumber.isNotEmpty) {
            final numStr = firstWithNumber['number'].toString();
            mascara = numStr.length >= 4
                ? '•••• ${numStr.substring(numStr.length - 4)}'
                : '•••• $numStr';
          }
        }
      }
    } catch (_) {}

    return ContaBancariaConectada(
      id: itemId,
      nomeBanco: nomeBanco,
      tipoConta: tipoConta,
      corHex: corHex,
      ultimoSync: lastSync,
      status: status,
      itemIdPluggy: itemId,
      mascaraCartao: mascara,
      capturaAutomaticaAtiva: true,
    );
  }

  /// Busca os bancos conectados (Items) do usuário logado.
  Future<List<ContaBancariaConectada>> buscarItensConectados({
    List<ContaBancariaConectada> contasExistentes = const [],
  }) async {
    http.Response? resp;
    try {
      resp = await _chamar('GET', '/items');
    } catch (_) {}

    if (resp != null && resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];
      final contas = <ContaBancariaConectada>[];
      for (final rawItem in results) {
        contas.add(await _mapearItem(rawItem as Map<String, dynamic>));
      }
      if (contas.isNotEmpty) return contas;
    }

    // Items conectados neste aparelho que ainda não constam no servidor:
    // buscarItemPorId os registra para o usuário (se forem dele).
    if (contasExistentes.isNotEmpty) {
      final atualizadas = <ContaBancariaConectada>[];
      for (final conta in contasExistentes) {
        if (conta.itemIdPluggy != null &&
            !conta.itemIdPluggy!.startsWith('pluggy_item_') &&
            !conta.itemIdPluggy!.startsWith('banco_')) {
          try {
            final atual = await buscarItemPorId(conta.itemIdPluggy!);
            atualizadas.add(atual);
          } catch (_) {
            atualizadas.add(conta);
          }
        } else {
          atualizadas.add(conta);
        }
      }
      return atualizadas;
    }

    return [];
  }

  /// Apaga a conexão na Pluggy e no registro do servidor (não só no aparelho).
  Future<void> removerConexao(String itemId) async {
    final resp = await _chamar(
      'DELETE',
      '/items/${Uri.encodeComponent(itemId)}',
    );
    if (resp.statusCode >= 400 && resp.statusCode != 404) {
      throw Exception('Não foi possível remover a conexão '
          '(Status ${resp.statusCode}).');
    }
  }

  /// Apaga todas as conexões do usuário logado. Devolve quantas saíram.
  Future<int> removerTodasConexoes() async {
    final resp = await _chamar('DELETE', '/items');
    if (resp.statusCode != 200) {
      throw Exception('Não foi possível remover as conexões '
          '(Status ${resp.statusCode}).');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['removidas'] as num?)?.toInt() ?? 0;
  }

  static const int _maxPaginasTransacoes = 20;

  /// Contas já buscadas nesta sincronização (evita pedir /accounts de novo
  /// para as transações — cada chamada conta na cota diária).
  final Map<String, List<dynamic>> _contasPorItem = {};

  /// Transações de uma conta via `GET /v2/transactions` (paginação por cursor:
  /// cada resposta traz em `next` a query string da próxima página, ou null).
  Future<List<dynamic>> _transacoesDaConta(
    String accountId,
    String dataDesde,
  ) async {
    final todas = <dynamic>[];
    var query = Uri(queryParameters: {
      'accountId': accountId,
      'dateFrom': dataDesde,
    }).query;
    for (var pagina = 0; pagina < _maxPaginasTransacoes; pagina++) {
      final resp = await _chamar('GET', '/v2/transactions?$query');
      if (resp.statusCode != 200) break;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      todas.addAll((data['results'] as List<dynamic>?) ?? const []);
      final proxima = data['next'] as String?;
      if (proxima == null || proxima.isEmpty) break;
      final params = Map<String, String>.of(
        Uri.splitQueryString(
          proxima.startsWith('?') ? proxima.substring(1) : proxima,
        ),
      )..putIfAbsent('accountId', () => accountId);
      query = Uri(queryParameters: params).query;
    }
    return todas;
  }

  /// Busca as transações bancárias reais de todas as contas associadas aos itens conectados.
  Future<List<TransacaoBancariaImportada>> buscarTodasTransacoes({
    List<ContaBancariaConectada>? contas,
    DateTime? desde,
  }) async {
    final itens = contas ?? await buscarItensConectados();
    final todasTransacoes = <TransacaoBancariaImportada>[];

    final dataDesdeStr = desde != null
        ? desde.toIso8601String().substring(0, 10)
        : DateTime.now().subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);

    for (final item in itens) {
      final itemId = item.itemIdPluggy ?? item.id;
      if (itemId.startsWith('pluggy_item_') || itemId.startsWith('banco_')) {
        continue;
      }

      try {
        var accounts = _contasPorItem.remove(itemId);
        if (accounts == null) {
          final accResp = await _chamar(
            'GET',
            '/accounts?itemId=${Uri.encodeQueryComponent(itemId)}',
          );
          if (accResp.statusCode != 200) continue;
          final accData = jsonDecode(accResp.body) as Map<String, dynamic>;
          accounts = (accData['results'] as List<dynamic>?) ?? [];
        }

        for (final rawAcc in accounts) {
          final acc = rawAcc as Map<String, dynamic>;
          final accountId = acc['id'] as String;
          final accType = (acc['type'] as String? ?? 'BANK').toUpperCase();
          final isCreditCard = accType == 'CREDIT';
          final accName = (acc['name'] as String?)?.trim();
          // Conexões Meu Pluggy juntam vários bancos: usa o nome da conta.
          final nomeRealBanco = (accName != null &&
                  accName.isNotEmpty &&
                  (item.nomeBanco.contains('Pluggy') ||
                      item.nomeBanco == 'Banco' ||
                      item.nomeBanco.contains(accName)))
              ? accName
              : item.nomeBanco;

          final txList = await _transacoesDaConta(accountId, dataDesdeStr);

          for (final rawTx in txList) {
            final tx = rawTx as Map<String, dynamic>;
            final txId = tx['id'] as String;
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final valorCents = (amount.abs() * 100).round();

            if (valorCents == 0) continue;

            final desc = (tx['description'] as String?) ??
                (tx['descriptionRaw'] as String?) ??
                'Transação $nomeRealBanco';

            if (ehPagamentoDeFatura(tx['category'] as String?, desc)) continue;
            final isReceita = ehEntrada(amount: amount, cartaoDeCredito: isCreditCard);

            final dateStr = tx['date'] as String?;
            final data = dateStr != null
                ? DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now()
                : DateTime.now();

            final paymentData = tx['paymentData'] as Map<String, dynamic>?;
            final paymentMethod =
                (paymentData?['paymentMethod'] as String? ?? '').toUpperCase();
            final isPix = paymentMethod == 'PIX' ||
                desc.toLowerCase().contains('pix');

            final formaPagamento = isPix
                ? 'Pix'
                : (isCreditCard
                    ? 'Cartão: $nomeRealBanco'
                    : 'Conta: $nomeRealBanco');

            final categoriaRaw = tx['category'] as String?;
            final categoria = categoriaNeutra(
                  categoriaPluggy: categoriaRaw,
                  descricao: desc,
                  paymentData: paymentData,
                  entrada: isReceita,
                  cpfTitular: acc['taxNumber'] as String?,
                  nomeTitular: acc['owner'] as String?,
                ) ??
                _mapearCategoria(categoriaRaw, desc);

            todasTransacoes.add(
              TransacaoBancariaImportada(
                id: txId,
                nomeBanco: nomeRealBanco,
                descricao: desc,
                valorCents: valorCents,
                isReceita: isReceita,
                formaPagamento: formaPagamento,
                data: data,
                origem: OrigemTransacaoBancaria.openFinance,
                categoriaSugerida: categoria,
                estabelecimento: desc,
              ),
            );
          }
        }
      } catch (_) {
        // Continua com os demais itens caso ocorra falha em uma conta específica
      }
    }

    return todasTransacoes;
  }

  static const int _maxPaginasInvestimentos = 10;

  /// Investimentos (CDB, fundos, ações, previdência…) de todas as conexões.
  Future<InvestimentosOpenFinance> buscarInvestimentos(
    List<ContaBancariaConectada> contas,
  ) async {
    final investimentos = <Investimento>[];
    var completo = true;
    for (final conta in contas) {
      final itemId = conta.itemIdPluggy ?? conta.id;
      if (itemId.startsWith('pluggy_item_') || itemId.startsWith('banco_')) {
        continue;
      }
      try {
        for (var pagina = 1; pagina <= _maxPaginasInvestimentos; pagina++) {
          final query = Uri(queryParameters: {
            'itemId': itemId,
            'page': '$pagina',
            'pageSize': '500',
          }).query;
          final resp = await _chamar('GET', '/investments?$query');
          if (resp.statusCode != 200) {
            completo = false;
            break;
          }
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          for (final raw in (data['results'] as List<dynamic>?) ?? const []) {
            final inv = investimentoDaPluggy(raw as Map<String, dynamic>);
            if (inv != null) investimentos.add(inv);
          }
          final totalPaginas = (data['totalPages'] as num?)?.toInt() ?? 1;
          if (pagina >= totalPaginas) break;
        }
      } catch (_) {
        completo = false;
      }
    }
    return InvestimentosOpenFinance(
      investimentos: investimentos,
      completo: completo,
    );
  }

  /// Conecta uma nova instituição bancária localmente ou via Pluggy.
  Future<ContaBancariaConectada> conectarBanco({
    required String nomeBanco,
    required String tipoConta,
    String? corHex,
    String? itemIdPluggy,
  }) async {
    final id = itemIdPluggy ?? 'banco_${DateTime.now().millisecondsSinceEpoch}';
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
      itemIdPluggy: itemIdPluggy ?? 'pluggy_item_$id',
    );
  }

  String _mapearCategoria(String? categoriaPluggy, String descricao) {
    if (categoriaPluggy != null && categoriaPluggy.isNotEmpty) {
      final cat = categoriaPluggy.toLowerCase();
      if (cat.contains('food') ||
          cat.contains('restauran') ||
          cat.contains('refeição') ||
          cat.contains('alimenta')) {
        return 'Alimentação';
      }
      if (cat.contains('transport') ||
          cat.contains('gas') ||
          cat.contains('combust') ||
          cat.contains('uber')) {
        return 'Transporte';
      }
      if (cat.contains('health') ||
          cat.contains('saude') ||
          cat.contains('saúde') ||
          cat.contains('pharmacy') ||
          cat.contains('farm')) {
        return 'Saúde';
      }
      if (cat.contains('entertainment') ||
          cat.contains('lazer') ||
          cat.contains('stream') ||
          cat.contains('cinema')) {
        return 'Lazer';
      }
      if (cat.contains('shopping') ||
          cat.contains('compra') ||
          cat.contains('loja')) {
        return 'Compras';
      }
      if (cat.contains('educat') || cat.contains('educa')) {
        return 'Educação';
      }
      if (cat.contains('home') ||
          cat.contains('moradia') ||
          cat.contains('aluguel') ||
          cat.contains('luz') ||
          cat.contains('água')) {
        return 'Moradia';
      }
    }

    final lowerDesc = descricao.toLowerCase();
    if (lowerDesc.contains('ifood') ||
        lowerDesc.contains('mercado') ||
        lowerDesc.contains('supermercado') ||
        lowerDesc.contains('restaurante') ||
        lowerDesc.contains('padaria')) {
      return 'Alimentação';
    }
    if (lowerDesc.contains('uber') ||
        lowerDesc.contains('99') ||
        lowerDesc.contains('posto') ||
        lowerDesc.contains('gasolina')) {
      return 'Transporte';
    }
    if (lowerDesc.contains('farmacia') ||
        lowerDesc.contains('drogaria') ||
        lowerDesc.contains('hospital')) {
      return 'Saúde';
    }
    return 'Outros';
  }
}
