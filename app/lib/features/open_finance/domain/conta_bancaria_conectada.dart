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
    );
  }
}
