import 'fatura_cartao.dart';

/// Representa o status da conexão da conta no Open Finance.
enum StatusConexaoBanco {
  conectado('conectado', 'Conectado'),
  sincronizando('sincronizando', 'Sincronizando'),
  requerReautenticacao('requer_reautenticacao', 'Requer Reautenticação'),
  erro('erro', 'Erro de Conexão');

  const StatusConexaoBanco(this.dbValue, this.rotulo);

  final String dbValue;
  final String rotulo;

  static StatusConexaoBanco fromDb(String dbValue) =>
      StatusConexaoBanco.values.firstWhere(
        (s) => s.dbValue == dbValue,
        orElse: () => StatusConexaoBanco.conectado,
      );
}

/// Modelo de uma instituição bancária / conta conectada via Open Finance.
class ContaBancariaConectada {
  const ContaBancariaConectada({
    required this.id,
    required this.nomeBanco,
    required this.tipoConta,
    required this.corHex,
    required this.ultimoSync,
    this.status = StatusConexaoBanco.conectado,
    this.mascaraCartao,
    this.itemIdPluggy,
    this.capturaAutomaticaAtiva = true,
    this.saldoContasCents,
    this.faturaCartoesCents,
    this.cartoes = const [],
  });

  final String id;
  final String nomeBanco;
  final String tipoConta; // ex: "Conta Corrente", "Cartão de Crédito"
  final String corHex;
  final DateTime ultimoSync;
  final StatusConexaoBanco status;
  final String? mascaraCartao;
  final String? itemIdPluggy;
  final bool capturaAutomaticaAtiva;

  /// Soma do saldo disponível das contas (corrente/poupança) desta conexão,
  /// como a Pluggy informa na última sincronização. Null se não veio.
  final int? saldoContasCents;

  /// Soma das faturas em aberto dos cartões desta conexão (o que se deve).
  /// Nas conexões Open Finance é o limite usado (inclui parcelas futuras).
  final int? faturaCartoesCents;

  /// Cartões de crédito desta conexão com as faturas fechadas.
  final List<CartaoOpenFinance> cartoes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_banco': nomeBanco,
      'tipo_conta': tipoConta,
      'cor_hex': corHex,
      'ultimo_sync': ultimoSync.toIso8601String(),
      'status': status.dbValue,
      'mascara_cartao': mascaraCartao,
      'item_id_pluggy': itemIdPluggy,
      'captura_automatica_ativa': capturaAutomaticaAtiva,
      'saldo_contas_cents': saldoContasCents,
      'fatura_cartoes_cents': faturaCartoesCents,
      'cartoes': [for (final c in cartoes) c.toMap()],
    };
  }

  factory ContaBancariaConectada.fromMap(Map<String, dynamic> map) {
    return ContaBancariaConectada(
      id: map['id'] as String,
      nomeBanco: map['nome_banco'] as String,
      tipoConta: map['tipo_conta'] as String,
      corHex: (map['cor_hex'] as String?) ?? '#8A05BE',
      ultimoSync: map['ultimo_sync'] != null
          ? DateTime.parse(map['ultimo_sync'] as String)
          : DateTime.now(),
      status: StatusConexaoBanco.fromDb((map['status'] as String?) ?? 'conectado'),
      mascaraCartao: map['mascara_cartao'] as String?,
      itemIdPluggy: map['item_id_pluggy'] as String?,
      capturaAutomaticaAtiva: (map['captura_automatica_ativa'] as bool?) ?? true,
      saldoContasCents: (map['saldo_contas_cents'] as num?)?.toInt(),
      faturaCartoesCents: (map['fatura_cartoes_cents'] as num?)?.toInt(),
      cartoes: [
        for (final c in (map['cartoes'] as List<dynamic>? ?? const []))
          CartaoOpenFinance.fromMap(c as Map<String, dynamic>),
      ],
    );
  }
}
