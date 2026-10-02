/// Contas de outra titularidade que o usuário declarou como dele (ex.: conta
/// no nome do cônjuge): transferências de/para elas não contam como gasto nem
/// como receita. A lista mora no `user_metadata.contas_proprias`, para valer
/// também na importação do servidor (`pluggy-webhook`).
abstract class ContasPropriasRepository {
  Future<List<String>> listar();

  /// Passa a tratar [nome] como conta própria e reclassifica os lançamentos
  /// importados com essa contraparte. Devolve quantos mudaram.
  Future<int> marcar(String nome);
}

String normalizarNomeConta(String nome) =>
    nome.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Quem está do outro lado, pela descrição do banco: "Pix enviado - NOME" ou
/// "Transferência Recebida|NOME". Null se a descrição não traz um nome.
String? contraparteDaDescricao(String descricao) {
  final partes = descricao.split(RegExp(r'\s+-\s+|\|'));
  if (partes.length < 2) return null;
  final nome = partes.last.trim();
  return nome.length >= 3 ? nome : null;
}

/// Algum dos [candidatos] (nome da contraparte) é uma das [nomesProprios]?
bool ehContaPropria(
  Iterable<String> nomesProprios,
  Iterable<String?> candidatos,
) {
  final proprios = {
    for (final n in nomesProprios)
      if (normalizarNomeConta(n).isNotEmpty) normalizarNomeConta(n),
  };
  if (proprios.isEmpty) return false;
  return candidatos
      .whereType<String>()
      .map(normalizarNomeConta)
      .any(proprios.contains);
}
