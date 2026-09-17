import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/investimento.dart';

class CotacoesService {
  CotacoesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _cryptoAliases = {
    'BITCOIN': 'BTC',
    'ETHEREUM': 'ETH',
    'SOLANA': 'SOL',
    'RIPPLE': 'XRP',
    'CARDANO': 'ADA',
    'TETHER': 'USDT',
    'DOGECOIN': 'DOGE',
  };

  /// Busca o preço atual em centavos para um ticker/nome de ativo.
  /// Retorna null se a cotação não puder ser obtida.
  Future<int?> buscarPrecoCents(String tickerOuNome, TipoClasseInvestimento classe) async {
    final limpo = tickerOuNome.trim().toUpperCase();
    if (limpo.isEmpty) return null;

    if (classe == TipoClasseInvestimento.cripto) {
      return _buscarPrecoCripto(limpo);
    } else if (classe == TipoClasseInvestimento.acao || classe == TipoClasseInvestimento.fii) {
      return _buscarPrecoAcaoOuFii(limpo);
    }

    return null;
  }

  Future<int?> _buscarPrecoCripto(String symbol) async {
    final cryptoSymbol = _cryptoAliases[symbol] ?? symbol;
    
    // Tenta via AwesomeAPI (BRL)
    try {
      final uri = Uri.parse('https://economia.awesomeapi.com.br/json/last/$cryptoSymbol-BRL');
      final resp = await _client.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final key = '${cryptoSymbol}BRL';
        if (data.containsKey(key)) {
          final precoStr = data[key]['bid'] ?? data[key]['high'];
          final precoNum = double.tryParse(precoStr.toString());
          if (precoNum != null && precoNum > 0) {
            return (precoNum * 100).round();
          }
        }
      }
    } catch (_) {}

    // Fallback Yahoo Finance para Cripto
    try {
      final yahooUri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cryptoSymbol-BRL');
      final resp = await _client.get(yahooUri, headers: {'User-Agent': 'Mozilla/5.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final result = data['chart']?['result'];
        if (result is List && result.isNotEmpty) {
          final price = result[0]?['meta']?['regularMarketPrice'];
          if (price is num && price > 0) {
            return (price.toDouble() * 100).round();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<int?> _buscarPrecoAcaoOuFii(String symbol) async {
    final tickerB3 = symbol.endsWith('.SA') ? symbol.substring(0, symbol.length - 3) : symbol;

    // 1. Tenta Yahoo Finance (Ticker.SA)
    try {
      final uri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$tickerB3.SA');
      final resp = await _client.get(uri, headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final result = data['chart']?['result'];
        if (result is List && result.isNotEmpty) {
          final price = result[0]?['meta']?['regularMarketPrice'];
          if (price is num && price > 0) {
            return (price.toDouble() * 100).round();
          }
        }
      }
    } catch (_) {}

    // 2. Fallback Brapi API
    try {
      final brapiUri = Uri.parse('https://brapi.dev/api/quote/$tickerB3');
      final resp = await _client.get(brapiUri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = data['results'];
        if (results is List && results.isNotEmpty) {
          final price = results[0]['regularMarketPrice'];
          if (price is num && price > 0) {
            return (price.toDouble() * 100).round();
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
