import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../domain/conta_bancaria_conectada.dart';
import '../domain/transacao_bancaria_importada.dart';
import 'open_finance_repository.dart';

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

class PluggyOpenFinanceService {
  final http.Client _httpClient;

  PluggyOpenFinanceService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String baseUrl = 'https://api.pluggy.ai';
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

  /// Obtém a API Key válida a partir do Client ID e Secret ou da chave direta informada.
  Future<String> obterApiKey(PluggyCredentials creds) async {
    // 1. Se tem API Key informada diretamente, valida-a
    if (creds.apiKey != null && creds.apiKey!.trim().isNotEmpty) {
      return creds.apiKey!.trim();
    }

    // 2. Se tem Client ID e Secret, faz o login via /auth
    if (creds.clientId != null &&
        creds.clientId!.trim().isNotEmpty &&
        creds.clientSecret != null &&
        creds.clientSecret!.trim().isNotEmpty) {
      final resp = await _httpClient.post(
        Uri.parse('$baseUrl/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': creds.clientId!.trim(),
          'clientSecret': creds.clientSecret!.trim(),
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['apiKey'] as String?;
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
      throw Exception(
        'Falha ao autenticar na Pluggy (Status ${resp.statusCode}). Verifique o Client ID e Client Secret.',
      );
    }

    throw Exception('Credenciais da Pluggy não fornecidas.');
  }

  /// Testa se as credenciais fornecidas são válidas chamando a API da Pluggy.
  Future<bool> testarConexao(PluggyCredentials creds) async {
    try {
      final apiKey = await obterApiKey(creds);
      // Tenta listar conectores (disponível em todas as contas)
      final resp = await _httpClient.get(
        Uri.parse('$baseUrl/connectors?pageSize=1'),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) return true;

      // Fallback para mock/outras configurações
      final fallback = await _httpClient.get(
        Uri.parse('$baseUrl/items?pageSize=1'),
        headers: {'X-API-KEY': apiKey},
      );
      return fallback.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Gera um Connect Token temporário para carregar o widget oficial da Pluggy.
  Future<String> gerarConnectToken(
    PluggyCredentials creds, {
    int? connectorId,
    String? oauthRedirectUri,
  }) async {
    final apiKey = await obterApiKey(creds);
    final Map<String, dynamic> options = {};
    if (connectorId != null) {
      options['connectorId'] = connectorId;
    }
    if (oauthRedirectUri != null && oauthRedirectUri.isNotEmpty) {
      options['oauthRedirectUri'] = oauthRedirectUri;
    }

    final body = options.isNotEmpty ? {'options': options} : <String, dynamic>{};

    final resp = await _httpClient.post(
      Uri.parse('$baseUrl/connect_token'),
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
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
  Future<void> abrirWidgetConexao(
    PluggyCredentials creds, {
    int? connectorId,
    String? oauthRedirectUri,
  }) async {
    final connectToken = await gerarConnectToken(
      creds,
      connectorId: connectorId,
      oauthRedirectUri: oauthRedirectUri,
    );
    final url = Uri.parse('https://connect.pluggy.ai/?connect_token=$connectToken');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Não foi possível abrir o navegador para autenticação.');
    }
  }

  /// Busca um item específico da Pluggy pelo seu ID.
  Future<ContaBancariaConectada> buscarItemPorId(
    PluggyCredentials creds,
    String itemId,
  ) async {
    final apiKey = await obterApiKey(creds);
    final resp = await _httpClient.get(
      Uri.parse('$baseUrl/items/$itemId'),
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Item não localizado na Pluggy (Status ${resp.statusCode}). Verifique o ID fornecido.',
      );
    }

    final item = jsonDecode(resp.body) as Map<String, dynamic>;
    final connector = item['connector'] as Map<String, dynamic>? ?? {};
    final nomeBanco = connector['name'] as String? ?? 'Banco Conectado';
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

    String tipoConta = 'Conta & Cartão';
    String? mascara;

    try {
      final accResp = await _httpClient.get(
        Uri.parse('$baseUrl/accounts?itemId=$itemId'),
        headers: {'X-API-KEY': apiKey},
      );
      if (accResp.statusCode == 200) {
        final accData = jsonDecode(accResp.body) as Map<String, dynamic>;
        final accounts = (accData['results'] as List<dynamic>?) ?? [];
        if (accounts.isNotEmpty) {
          final accList = accounts.cast<Map<String, dynamic>>();
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

  /// Busca todos os bancos conectados (Items) pelo usuário na Pluggy.
  Future<List<ContaBancariaConectada>> buscarItensConectados(
    PluggyCredentials creds, {
    List<ContaBancariaConectada> contasExistentes = const [],
  }) async {
    final apiKey = await obterApiKey(creds);

    // Tenta primeiro os endpoints de listagem (/v2/items ou /items)
    http.Response? resp;
    try {
      resp = await _httpClient.get(
        Uri.parse('$baseUrl/v2/items'),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode != 200) {
        resp = await _httpClient.get(
          Uri.parse('$baseUrl/items'),
          headers: {
            'X-API-KEY': apiKey,
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (_) {}

    if (resp != null && resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];
      final contas = <ContaBancariaConectada>[];

      for (final rawItem in results) {
        final item = rawItem as Map<String, dynamic>;
        final itemId = item['id'] as String;
        final connector = item['connector'] as Map<String, dynamic>? ?? {};
        final nomeBanco = connector['name'] as String? ?? 'Banco';
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
          final accResp = await _httpClient.get(
            Uri.parse('$baseUrl/accounts?itemId=$itemId'),
            headers: {'X-API-KEY': apiKey},
          );
          if (accResp.statusCode == 200) {
            final accData = jsonDecode(accResp.body) as Map<String, dynamic>;
            final accounts = (accData['results'] as List<dynamic>?) ?? [];
            if (accounts.isNotEmpty) {
              final accList = accounts.cast<Map<String, dynamic>>();
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

        contas.add(
          ContaBancariaConectada(
            id: itemId,
            nomeBanco: nomeBanco,
            tipoConta: tipoConta,
            corHex: corHex,
            ultimoSync: lastSync,
            status: status,
            itemIdPluggy: itemId,
            mascaraCartao: mascara,
            capturaAutomaticaAtiva: true,
          ),
        );
      }

      return contas;
    }

    // Se o plano da Pluggy for auto-serviço/desenvolvedor (LIST_ITEMS_FEATURE_NOT_ENABLED):
    // Atualiza individualmente as contas já conhecidas/salvas no dispositivo
    if (contasExistentes.isNotEmpty) {
      final atualizadas = <ContaBancariaConectada>[];
      for (final conta in contasExistentes) {
        if (conta.itemIdPluggy != null &&
            !conta.itemIdPluggy!.startsWith('pluggy_item_') &&
            !conta.itemIdPluggy!.startsWith('banco_')) {
          try {
            final atual = await buscarItemPorId(creds, conta.itemIdPluggy!);
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

  /// Busca as transações bancárias reais de todas as contas associadas aos itens conectados.
  Future<List<TransacaoBancariaImportada>> buscarTodasTransacoes(
    PluggyCredentials creds, {
    List<ContaBancariaConectada>? contas,
    DateTime? desde,
  }) async {
    final apiKey = await obterApiKey(creds);
    final itens = contas ?? await buscarItensConectados(creds);
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
        final accResp = await _httpClient.get(
          Uri.parse('$baseUrl/accounts?itemId=$itemId'),
          headers: {'X-API-KEY': apiKey},
        );
        if (accResp.statusCode != 200) continue;

        final accData = jsonDecode(accResp.body) as Map<String, dynamic>;
        final accounts = (accData['results'] as List<dynamic>?) ?? [];

        for (final rawAcc in accounts) {
          final acc = rawAcc as Map<String, dynamic>;
          final accountId = acc['id'] as String;
          final accType = (acc['type'] as String? ?? 'BANK').toUpperCase();
          final isCreditCard = accType == 'CREDIT';

          final txResp = await _httpClient.get(
            Uri.parse('$baseUrl/transactions?accountId=$accountId&from=$dataDesdeStr&pageSize=100'),
            headers: {'X-API-KEY': apiKey},
          );

          if (txResp.statusCode != 200) continue;

          final txData = jsonDecode(txResp.body) as Map<String, dynamic>;
          final txList = (txData['results'] as List<dynamic>?) ?? [];

          for (final rawTx in txList) {
            final tx = rawTx as Map<String, dynamic>;
            final txId = tx['id'] as String;
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final typeStr = (tx['type'] as String? ?? '').toUpperCase();
            final isReceita = amount > 0 || typeStr == 'CREDIT';
            final valorCents = (amount.abs() * 100).round();

            if (valorCents == 0) continue;

            final desc = (tx['description'] as String?) ??
                (tx['descriptionRaw'] as String?) ??
                'Transação ${item.nomeBanco}';

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
                    ? 'Cartão: ${item.nomeBanco}'
                    : 'Conta: ${item.nomeBanco}');

            final categoriaRaw = tx['category'] as String?;
            final categoria = _mapearCategoria(categoriaRaw, desc);

            todasTransacoes.add(
              TransacaoBancariaImportada(
                id: txId,
                nomeBanco: item.nomeBanco,
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
