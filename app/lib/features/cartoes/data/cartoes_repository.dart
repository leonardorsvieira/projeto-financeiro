import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cartao_credito.dart';

const String _cartoesKey = 'meubolso_cartoes_credito';

class CartoesRepository {
  List<CartaoCredito> _cache = [];

  static const List<CartaoCredito> cartoesPadrao = [
    CartaoCredito(
      id: 'default-nubank',
      nome: 'Nubank',
      diaFechamento: 5,
      diaVencimento: 12,
      corHex: '#8A05BE',
    ),
    CartaoCredito(
      id: 'default-inter',
      nome: 'Banco Inter',
      diaFechamento: 1,
      diaVencimento: 10,
      corHex: '#FF7A00',
    ),
  ];

  Future<List<CartaoCredito>> getCartoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cartoesKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        _cache = List.from(cartoesPadrao);
        await _salvarCache(prefs);
        return _cache;
      }
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      _cache = list
          .map((e) => CartaoCredito.fromMap(e as Map<String, dynamic>))
          .toList();
      if (_cache.isEmpty) {
        _cache = List.from(cartoesPadrao);
        await _salvarCache(prefs);
      }
      return _cache;
    } catch (_) {
      return cartoesPadrao;
    }
  }

  Future<void> salvarCartao(CartaoCredito cartao) async {
    final list = await getCartoes();
    final index = list.indexWhere((c) => c.id == cartao.id);
    if (index >= 0) {
      list[index] = cartao;
    } else {
      list.add(cartao);
    }
    _cache = list;
    final prefs = await SharedPreferences.getInstance();
    await _salvarCache(prefs);
  }

  Future<void> excluirCartao(String id) async {
    final list = await getCartoes();
    list.removeWhere((c) => c.id == id);
    _cache = list;
    final prefs = await SharedPreferences.getInstance();
    await _salvarCache(prefs);
  }

  Future<void> _salvarCache(SharedPreferences prefs) async {
    final jsonStr = jsonEncode(_cache.map((c) => c.toMap()).toList());
    await prefs.setString(_cartoesKey, jsonStr);
  }
}
