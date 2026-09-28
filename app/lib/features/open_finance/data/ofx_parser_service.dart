import '../domain/transacao_bancaria_importada.dart';

class OfxParserService {
  OfxParserService._();

  /// Converte o conteúdo de um arquivo .ofx em uma lista de transações bancárias.
  static List<TransacaoBancariaImportada> parseOFX(String conteudoOfx) {
    final transacoes = <TransacaoBancariaImportada>[];
    if (conteudoOfx.isEmpty) return transacoes;

    final regexStmtTrn = RegExp(
      r'<STMTTRN>(.*?)</STMTTRN>',
      multiLine: true,
      caseSensitive: false,
      dotAll: true,
    );

    Iterable<Match> matches = regexStmtTrn.allMatches(conteudoOfx);

    // Se o OFX não fechar a tag </STMTTRN> (SGML antigo), divide pela tag inicial <STMTTRN>
    if (matches.isEmpty) {
      final partes = conteudoOfx.split(RegExp(r'<STMTTRN>', caseSensitive: false));
      for (var i = 1; i < partes.length; i++) {
        final t = _parseBlocoTrn(partes[i]);
        if (t != null) transacoes.add(t);
      }
      return transacoes;
    }

    for (final match in matches) {
      final bloco = match.group(1) ?? '';
      final t = _parseBlocoTrn(bloco);
      if (t != null) transacoes.add(t);
    }

    return transacoes;
  }

  static TransacaoBancariaImportada? _parseBlocoTrn(String bloco) {
    final trnType = _extrairTag(bloco, 'TRNTYPE');
    final dtPostedStr = _extrairTag(bloco, 'DTPOSTED');
    final trnAmtStr = _extrairTag(bloco, 'TRNAMT');
    final memo = _extrairTag(bloco, 'MEMO');
    final name = _extrairTag(bloco, 'NAME');
    final fitId = _extrairTag(bloco, 'FITID');

    if (trnAmtStr.isEmpty) return null;

    final valorDouble = double.tryParse(trnAmtStr.replaceAll(',', '.')) ?? 0.0;
    final isReceita = valorDouble > 0 || trnType.toUpperCase() == 'CREDIT';
    final valorCents = (valorDouble.abs() * 100).round();

    if (valorCents == 0) return null;

    final data = _parseDataOfx(dtPostedStr);
    final desc = name.isNotEmpty ? name : (memo.isNotEmpty ? memo : 'Transação OFX');
    final isPix = desc.toLowerCase().contains('pix') || memo.toLowerCase().contains('pix');
    final formaPagamento = isPix ? 'Pix' : 'Cartão / Conta Bancária';

    return TransacaoBancariaImportada(
      id: fitId.isNotEmpty ? fitId : 'ofx_${DateTime.now().microsecondsSinceEpoch}',
      nomeBanco: 'Extrato OFX',
      descricao: desc,
      valorCents: valorCents,
      isReceita: isReceita,
      formaPagamento: formaPagamento,
      data: data,
      origem: OrigemTransacaoBancaria.arquivoOfx,
      categoriaSugerida: 'Outros',
      estabelecimento: desc,
    );
  }

  static String _extrairTag(String bloco, String tag) {
    // Tenta formato XML <TAG>conteudo</TAG> ou SGML <TAG>conteudo\n
    final regXml = RegExp('<$tag>(.*?)</$tag>', caseSensitive: false, dotAll: true);
    final matchXml = regXml.firstMatch(bloco);
    if (matchXml != null) return matchXml.group(1)!.trim();

    final regSgml = RegExp('<$tag>([^<\r\n]+)', caseSensitive: false);
    final matchSgml = regSgml.firstMatch(bloco);
    if (matchSgml != null) return matchSgml.group(1)!.trim();

    return '';
  }

  static DateTime _parseDataOfx(String dtPosted) {
    if (dtPosted.length >= 8) {
      final ano = int.tryParse(dtPosted.substring(0, 4)) ?? DateTime.now().year;
      final mes = int.tryParse(dtPosted.substring(4, 6)) ?? DateTime.now().month;
      final dia = int.tryParse(dtPosted.substring(6, 8)) ?? DateTime.now().day;
      return DateTime(ano, mes, dia);
    }
    return DateTime.now();
  }
}
