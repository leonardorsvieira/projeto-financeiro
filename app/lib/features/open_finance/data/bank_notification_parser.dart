import '../domain/transacao_bancaria_importada.dart';

class BankNotificationParser {
  BankNotificationParser._();

  /// Tenta identificar o banco, valor, estabelecimento, tipo e forma de pagamento a partir da notificação bancária.
  static TransacaoBancariaImportada? parseNotificacao({
    required String appPackageOuNome,
    required String titulo,
    required String texto,
    DateTime? dataHora,
  }) {
    final payload = '$titulo $texto'.trim();
    if (payload.isEmpty) return null;

    final dataFinal = dataHora ?? DateTime.now();
    final bancoIdentificado = _identificarBanco(appPackageOuNome, payload);

    // 1. Tenta extrair o valor financeiro (ex: R$ 45,90 ou 45,90)
    final matchValor = RegExp(
      r'R\$\s*([0-9]{1,3}(?:\.[0-9]{3})*\,[0-9]{2})|R\$\s*([0-9]+(?:\,[0-9]{2})?)',
      caseSensitive: false,
    ).firstMatch(payload);

    if (matchValor == null) return null;

    final valorRaw = (matchValor.group(1) ?? matchValor.group(2))!;
    final valorCents = _converterParaCentavos(valorRaw);
    if (valorCents <= 0) return null;

    final isReceita = _isReceita(payload);
    final isPix = payload.toLowerCase().contains('pix');
    final formaPagamento = isPix
        ? 'Pix'
        : (bancoIdentificado != 'Banco'
            ? 'Cartão: $bancoIdentificado'
            : 'Cartão de Crédito');

    final estabelecimento = _extrairEstabelecimento(payload);
    final descricao = estabelecimento.isNotEmpty
        ? estabelecimento
        : (isPix
            ? (isReceita ? 'Pix Recebido' : 'Pix Enviado')
            : 'Compra no $bancoIdentificado');

    final categoria = _sugerirCategoria(descricao, payload);

    return TransacaoBancariaImportada(
      id: 'notif_${dataFinal.millisecondsSinceEpoch}',
      nomeBanco: bancoIdentificado,
      descricao: descricao,
      valorCents: valorCents,
      isReceita: isReceita,
      formaPagamento: formaPagamento,
      data: dataFinal,
      origem: OrigemTransacaoBancaria.notificacaoPush,
      categoriaSugerida: categoria,
      estabelecimento: estabelecimento.isNotEmpty ? estabelecimento : null,
    );
  }

  static String _identificarBanco(String packageOuNome, String payload) {
    final lowerPkg = packageOuNome.toLowerCase();
    final lowerText = payload.toLowerCase();

    if (lowerPkg.contains('nubank') || lowerText.contains('nubank')) {
      return 'Nubank';
    }
    if (lowerPkg.contains('inter') || lowerText.contains('inter')) {
      return 'Inter';
    }
    if (lowerPkg.contains('itau') || lowerText.contains('itaú') || lowerText.contains('itau')) {
      return 'Itaú';
    }
    if (lowerPkg.contains('bradesco') || lowerText.contains('bradesco')) {
      return 'Bradesco';
    }
    if (lowerPkg.contains('santander') || lowerText.contains('santander')) {
      return 'Santander';
    }
    if (lowerPkg.contains('c6bank') || lowerText.contains('c6')) {
      return 'C6 Bank';
    }
    if (lowerPkg.contains('picpay') || lowerText.contains('picpay')) {
      return 'PicPay';
    }
    if (lowerPkg.contains('mercadopago') || lowerText.contains('mercado pago')) {
      return 'Mercado Pago';
    }
    if (lowerPkg.contains('caixa') || lowerText.contains('caixa')) {
      return 'Caixa';
    }

    return 'Banco';
  }

  static bool _isReceita(String text) {
    final lower = text.toLowerCase();
    return lower.contains('recebeu') ||
        lower.contains('recebido') ||
        lower.contains('depósito') ||
        lower.contains('crédito em conta');
  }

  static int _converterParaCentavos(String textoValor) {
    final limpo = textoValor
        .replaceAll('R\$', '')
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final val = double.tryParse(limpo) ?? 0.0;
    return (val * 100).round();
  }

  static String _extrairEstabelecimento(String text) {
    // Procura por "em [Nome]" ou "para [Nome]"
    final matchEm = RegExp(r'\b(?:em|no|na|para)\s+([A-Z0-9\s\.\&\-]+)', caseSensitive: false)
        .firstMatch(text);
    if (matchEm != null) {
      final res = matchEm.group(1)!.trim();
      if (res.length > 2 && !res.toLowerCase().startsWith('r\$')) {
        return res;
      }
    }
    return '';
  }

  static String _sugerirCategoria(String descricao, String payload) {
    final lower = '$descricao $payload'.toLowerCase();
    if (lower.contains('mercado') ||
        lower.contains('supermercado') ||
        lower.contains('ifood') ||
        lower.contains('restaurante') ||
        lower.contains('padaria') ||
        lower.contains('burger')) {
      return 'Alimentação';
    }
    if (lower.contains('uber') ||
        lower.contains('99') ||
        lower.contains('postodecombustivel') ||
        lower.contains('posto') ||
        lower.contains('combustível') ||
        lower.contains('estacionamento')) {
      return 'Transporte';
    }
    if (lower.contains('farmacia') || lower.contains('drogaria') || lower.contains('hospital')) {
      return 'Saúde';
    }
    if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('cinema')) {
      return 'Lazer';
    }
    return 'Outros';
  }
}
