import '../../lancamentos/domain/lancamento.dart';

/// Fatura fechada de um cartão, como o banco informou no Open Finance
/// (`GET /bills` da Pluggy).
class FaturaCartao {
  const FaturaCartao({
    required this.vencimento,
    required this.valorCents,
    this.fechamento,
  });

  final DateTime vencimento;
  final DateTime? fechamento;
  final int valorCents;

  Map<String, dynamic> toMap() => {
        'vencimento': _data(vencimento),
        'fechamento': fechamento == null ? null : _data(fechamento!),
        'valor_cents': valorCents,
      };

  factory FaturaCartao.fromMap(Map<String, dynamic> map) => FaturaCartao(
        vencimento: DateTime.parse(map['vencimento'] as String),
        fechamento: map['fechamento'] == null
            ? null
            : DateTime.parse(map['fechamento'] as String),
        valorCents: (map['valor_cents'] as num).toInt(),
      );
}

/// Cartão de crédito de uma conexão Open Finance e suas faturas fechadas.
class CartaoOpenFinance {
  const CartaoOpenFinance({
    required this.formasPagamento,
    this.faturas = const [],
    this.faturaAbertaCents,
  });

  /// Formas com que as compras do cartão são importadas ("Cartão: gold"): a
  /// primeira é a da sincronização do app; a outra, a do webhook.
  final List<String> formasPagamento;
  final List<FaturaCartao> faturas;

  /// Fatura aberta pelo banco: transações ainda sem fatura (`billId`). Null
  /// se o banco não informa (o app estima pelas compras importadas).
  final int? faturaAbertaCents;

  Map<String, dynamic> toMap() => {
        'formas_pagamento': formasPagamento,
        'faturas': [for (final f in faturas) f.toMap()],
        'fatura_aberta_cents': faturaAbertaCents,
      };

  factory CartaoOpenFinance.fromMap(Map<String, dynamic> map) =>
      CartaoOpenFinance(
        formasPagamento: [
          for (final f in map['formas_pagamento'] as List<dynamic>) f as String,
        ],
        faturas: [
          for (final f in (map['faturas'] as List<dynamic>? ?? const []))
            FaturaCartao.fromMap(f as Map<String, dynamic>),
        ],
        faturaAbertaCents: (map['fatura_aberta_cents'] as num?)?.toInt(),
      );
}

/// O que um cartão cobra no mês: a fatura que vence nele.
class FaturaDoMes {
  const FaturaDoMes({
    required this.formasPagamento,
    required this.valorCents,
    required this.vencimento,
    required this.aberta,
  });

  /// Formas de pagamento das compras do cartão (a primeira dá o nome).
  final List<String> formasPagamento;
  final int valorCents;
  final DateTime vencimento;

  /// true: fatura ainda aberta — compras desde o último fechamento até hoje
  /// (cresce até fechar; o vencimento é estimado).
  final bool aberta;
}

String _data(DateTime d) => d.toIso8601String().substring(0, 10);

String normalizarForma(String s) => s.trim().toLowerCase();

bool _noMes(DateTime d, DateTime mes) =>
    d.year == mes.year && d.month == mes.month;

/// Vencimento da fatura seguinte: mesmo dia no mês seguinte (31/01 → 28/02).
DateTime vencimentoSeguinte(DateTime d) {
  final ultimoDia = DateTime(d.year, d.month + 2, 0).day;
  return DateTime(d.year, d.month + 1, d.day > ultimoDia ? ultimoDia : d.day);
}

/// Fatura de cada cartão do Open Finance que vence em [mes]:
/// - fechada (veio do banco): o valor dela;
/// - a aberta (a seguinte à última fechada): a do banco
///   ([CartaoOpenFinance.faturaAbertaCents]); sem ela, compras − estornos do
///   cartão em [lancamentos] desde o último fechamento (sem a data,
///   vencimento − 7 dias) até [agora].
/// Cartões sem fatura para [mes] ficam de fora (o painel soma as compras do
/// mês, como antes). Cartões com a mesma forma de pagamento são somados.
List<FaturaDoMes> faturasDoMes({
  required List<CartaoOpenFinance> cartoes,
  required Iterable<Lancamento> lancamentos,
  required DateTime mes,
  required DateTime agora,
}) {
  // Agrupa pela forma principal; junta as formas, as faturas e os cartões.
  final formas = <String, List<String>>{};
  final faturasPorCartao = <String, List<FaturaCartao>>{};
  final cartoesDoGrupo = <String, List<CartaoOpenFinance>>{};
  for (final c in cartoes) {
    if (c.formasPagamento.isEmpty) continue;
    final chave = normalizarForma(c.formasPagamento.first);
    final lista = formas.putIfAbsent(chave, () => []);
    for (final f in c.formasPagamento) {
      if (!lista.any((x) => normalizarForma(x) == normalizarForma(f))) {
        lista.add(f);
      }
    }
    faturasPorCartao.putIfAbsent(chave, () => []).addAll(c.faturas);
    cartoesDoGrupo.putIfAbsent(chave, () => []).add(c);
  }

  final resultado = <FaturaDoMes>[];
  for (final chave in formas.keys) {
    final faturas = faturasPorCartao[chave]!;
    if (faturas.isEmpty) continue;
    final fechadas = faturas.where((f) => _noMes(f.vencimento, mes)).toList();
    if (fechadas.isNotEmpty) {
      resultado.add(FaturaDoMes(
        formasPagamento: formas[chave]!,
        valorCents: fechadas.fold(0, (s, f) => s + f.valorCents),
        vencimento: fechadas.first.vencimento,
        aberta: false,
      ));
      continue;
    }

    final ultima = faturas.reduce(
      (a, b) => a.vencimento.isAfter(b.vencimento) ? a : b,
    );
    final proximoVencimento = vencimentoSeguinte(ultima.vencimento);
    if (!_noMes(proximoVencimento, mes)) continue;
    final doBanco = cartoesDoGrupo[chave]!
        .where((c) => c.faturas.isNotEmpty)
        .map((c) => c.faturaAbertaCents)
        .toList();
    final int valor;
    if (doBanco.every((v) => v != null)) {
      valor = doBanco.fold(0, (s, v) => s + v!);
    } else {
      valor = _estimativaAberta(
        formas[chave]!,
        lancamentos,
        desde: ultima.fechamento ??
            ultima.vencimento.subtract(const Duration(days: 7)),
        agora: agora,
      );
    }
    resultado.add(FaturaDoMes(
      formasPagamento: formas[chave]!,
      valorCents: valor,
      vencimento: proximoVencimento,
      aberta: true,
    ));
  }
  return resultado;
}

/// Fatura aberta estimada pelas compras − estornos importados do cartão
/// ([formas]) entre [desde] e [agora], quando o banco não a informa.
int _estimativaAberta(
  List<String> formas,
  Iterable<Lancamento> lancamentos, {
  required DateTime desde,
  required DateTime agora,
}) {
  final doCartao = {for (final f in formas) normalizarForma(f)};
  var valor = 0;
  for (final l in lancamentos) {
    if (!doCartao.contains(normalizarForma(l.formaPagamento)) ||
        l.ehMovimentacaoNeutra) {
      continue;
    }
    if (l.data.isBefore(desde) || l.data.isAfter(agora)) continue;
    valor += l.tipo == TipoLancamento.receita ? -l.valorCents : l.valorCents;
  }
  return valor;
}
