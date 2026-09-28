import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/open_finance/data/ofx_parser_service.dart';
import 'package:meubolso/features/open_finance/domain/transacao_bancaria_importada.dart';

void main() {
  group('OfxParserService', () {
    // ─── Formato XML ──────────────────────────────────────────────────────────
    group('formato XML (tags fechadas)', () {
      const ofxXml = '''
<OFX>
  <BANKMSGSRSV1>
    <STMTTRNRS>
      <STMTRS>
        <BANKTRANLIST>
          <STMTTRN>
            <TRNTYPE>DEBIT</TRNTYPE>
            <DTPOSTED>20240315</DTPOSTED>
            <TRNAMT>-150.50</TRNAMT>
            <FITID>20240315001</FITID>
            <NAME>SUPERMERCADO EXTRA</NAME>
            <MEMO>Compra débito</MEMO>
          </STMTTRN>
          <STMTTRN>
            <TRNTYPE>CREDIT</TRNTYPE>
            <DTPOSTED>20240320</DTPOSTED>
            <TRNAMT>1200.00</TRNAMT>
            <FITID>20240320001</FITID>
            <NAME>SALARIO EMPRESA X</NAME>
            <MEMO>Depósito em conta</MEMO>
          </STMTTRN>
        </BANKTRANLIST>
      </STMTRS>
    </STMTTRNRS>
  </BANKMSGSRSV1>
</OFX>
''';

      test('parseia 2 transações em formato XML', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        expect(transacoes.length, equals(2));
      });

      test('valor em centavos correto para débito', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        final debito = transacoes.firstWhere((t) => !t.isReceita);
        expect(debito.valorCents, equals(15050));
      });

      test('valor em centavos correto para crédito', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        final credito = transacoes.firstWhere((t) => t.isReceita);
        expect(credito.valorCents, equals(120000));
      });

      test('isReceita correto para CREDIT', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        final credito = transacoes.firstWhere((t) => t.fitIdOuId.contains('20240320'));
        expect(credito.isReceita, isTrue);
      });

      test('isReceita falso para DEBIT', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        final debito = transacoes.firstWhere((t) => t.fitIdOuId.contains('20240315'));
        expect(debito.isReceita, isFalse);
      });

      test('data parseada corretamente', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        final debito = transacoes.firstWhere((t) => !t.isReceita);
        expect(debito.data, equals(DateTime(2024, 3, 15)));
      });

      test('descrição usa NAME quando disponível', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        expect(transacoes.first.descricao, equals('SUPERMERCADO EXTRA'));
      });

      test('origem é arquivoOfx', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        for (final t in transacoes) {
          expect(t.origem, equals(OrigemTransacaoBancaria.arquivoOfx));
        }
      });

      test('fitId preenchido corretamente', () {
        final transacoes = OfxParserService.parseOFX(ofxXml);
        expect(transacoes.first.id, equals('20240315001'));
      });
    });

    // ─── Formato SGML (sem tag de fechamento) ─────────────────────────────────
    group('formato SGML (sem tags de fechamento)', () {
      const ofxSgml = '''
<OFX>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20240101
<TRNAMT>-75,90
<FITID>sgml001
<NAME>POSTO SHELL
<MEMO>Combustivel
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20240102
<TRNAMT>500.00
<FITID>sgml002
<NAME>PIX RECEBIDO
<MEMO>Pix de amigo
''';

      test('parseia transações em formato SGML', () {
        final transacoes = OfxParserService.parseOFX(ofxSgml);
        expect(transacoes.length, greaterThanOrEqualTo(1));
      });
    });

    // ─── Casos extremos ───────────────────────────────────────────────────────
    group('casos extremos', () {
      test('retorna lista vazia para string vazia', () {
        final transacoes = OfxParserService.parseOFX('');
        expect(transacoes, isEmpty);
      });

      test('ignora transações com TRNAMT zero', () {
        const ofxZero = '''
<OFX>
  <STMTTRN>
    <TRNTYPE>DEBIT</TRNTYPE>
    <DTPOSTED>20240101</DTPOSTED>
    <TRNAMT>0.00</TRNAMT>
    <FITID>zero001</FITID>
    <NAME>TARIFA ZERO</NAME>
  </STMTTRN>
</OFX>
''';
        final transacoes = OfxParserService.parseOFX(ofxZero);
        expect(transacoes, isEmpty);
      });

      test('detecta Pix na forma de pagamento quando memo contém "pix"', () {
        const ofxPix = '''
<OFX>
  <STMTTRN>
    <TRNTYPE>DEBIT</TRNTYPE>
    <DTPOSTED>20240201</DTPOSTED>
    <TRNAMT>-100.00</TRNAMT>
    <FITID>pix001</FITID>
    <NAME>TRANSFER</NAME>
    <MEMO>Pix enviado</MEMO>
  </STMTTRN>
</OFX>
''';
        final transacoes = OfxParserService.parseOFX(ofxPix);
        expect(transacoes.first.formaPagamento, equals('Pix'));
      });

      test('usa MEMO como descrição quando NAME está ausente', () {
        const ofxSemName = '''
<OFX>
  <STMTTRN>
    <TRNTYPE>DEBIT</TRNTYPE>
    <DTPOSTED>20240301</DTPOSTED>
    <TRNAMT>-25.00</TRNAMT>
    <FITID>memo001</FITID>
    <MEMO>Pagamento fatura</MEMO>
  </STMTTRN>
</OFX>
''';
        final transacoes = OfxParserService.parseOFX(ofxSemName);
        expect(transacoes.first.descricao, equals('Pagamento fatura'));
      });

      test('DTPOSTED inválido retorna data próxima de now (não lança)', () {
        const ofxBadDate = '''
<OFX>
  <STMTTRN>
    <TRNTYPE>DEBIT</TRNTYPE>
    <DTPOSTED>invalid</DTPOSTED>
    <TRNAMT>-10.00</TRNAMT>
    <FITID>bd001</FITID>
    <NAME>Teste</NAME>
  </STMTTRN>
</OFX>
''';
        expect(() => OfxParserService.parseOFX(ofxBadDate), returnsNormally);
      });
    });
  });
}

// ─── Extensão auxiliar ──────────────────────────────────────────────────────
extension _IdHelper on TransacaoBancariaImportada {
  /// Atalho para acessar o id (usado nos testes de fitId).
  String get fitIdOuId => id;
}
