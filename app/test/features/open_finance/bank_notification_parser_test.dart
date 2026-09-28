import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/open_finance/data/bank_notification_parser.dart';
import 'package:meubolso/features/open_finance/domain/transacao_bancaria_importada.dart';

void main() {
  group('BankNotificationParser', () {
    // ─── Identificação de valor ───────────────────────────────────────────────
    group('extração de valor', () {
      test('reconhece R\$ com vírgula decimal', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Compra aprovada',
          texto: 'Você gastou R\$ 45,90 no iFood',
        );
        expect(t, isNotNull);
        expect(t!.valorCents, equals(4590));
      });

      test('reconhece valor com ponto como separador de milhar', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.itau',
          titulo: 'Compra aprovada',
          texto: 'Compra de R\$ 1.250,00 aprovada no Itaú',
        );
        expect(t, isNotNull);
        expect(t!.valorCents, equals(125000));
      });

      test('retorna null se não há valor monetário', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Promoção',
          texto: 'Aproveite nossas ofertas especiais!',
        );
        expect(t, isNull);
      });
    });

    // ─── Identificação de banco ───────────────────────────────────────────────
    group('identificação de banco', () {
      test('identifica Nubank pelo package name', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank.app',
          titulo: 'Compra aprovada',
          texto: 'R\$ 50,00 aprovado',
        );
        expect(t!.nomeBanco, equals('Nubank'));
      });

      test('identifica Inter pelo texto', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'unknown',
          titulo: 'Inter Notificação',
          texto: 'R\$ 30,00 debitado no Inter',
        );
        expect(t!.nomeBanco, equals('Inter'));
      });

      test('identifica PicPay pelo texto', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'br.com.picpay',
          titulo: 'Pagamento',
          texto: 'Você pagou R\$ 20,00 via PicPay',
        );
        expect(t!.nomeBanco, equals('PicPay'));
      });

      test('retorna "Banco" quando não identificado', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.desconhecido',
          titulo: 'Pagamento',
          texto: 'Você pagou R\$ 10,00',
        );
        expect(t!.nomeBanco, equals('Banco'));
      });
    });

    // ─── Tipo receita vs. despesa ─────────────────────────────────────────────
    group('tipo receita vs. despesa', () {
      test('detecta receita por "recebeu"', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Pix recebido',
          texto: 'Você recebeu R\$ 200,00 via Pix',
        );
        expect(t!.isReceita, isTrue);
      });

      test('detecta despesa por ausência de palavras de receita', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Compra',
          texto: 'Compra de R\$ 99,90 no Amazon',
        );
        expect(t!.isReceita, isFalse);
      });
    });

    // ─── Forma de pagamento ───────────────────────────────────────────────────
    group('forma de pagamento', () {
      test('identifica Pix quando texto contém "pix"', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Pix enviado',
          texto: 'Você enviou R\$ 80,00 via Pix',
        );
        expect(t!.formaPagamento, equals('Pix'));
      });

      test('usa cartão quando texto não menciona pix', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Compra aprovada',
          texto: 'Compra de R\$ 55,00 aprovada no Nubank',
        );
        expect(t!.formaPagamento, contains('Cartão'));
      });
    });

    // ─── Sugestão de categoria ────────────────────────────────────────────────
    group('sugestão de categoria', () {
      test('sugere Alimentação para iFood', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Compra',
          texto: 'R\$ 35,00 no iFood',
        );
        expect(t!.categoriaSugerida, equals('Alimentação'));
      });

      test('sugere Transporte para Uber', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.uber',
          titulo: 'Corrida',
          texto: 'R\$ 18,50 na Uber',
        );
        expect(t!.categoriaSugerida, equals('Transporte'));
      });

      test('sugere Saúde para farmácia', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.inter',
          titulo: 'Compra',
          texto: 'R\$ 42,00 na Farmacia Pacheco',
        );
        expect(t!.categoriaSugerida, equals('Saúde'));
      });

      test('sugere Lazer para Netflix', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.netflix',
          titulo: 'Cobrança',
          texto: 'R\$ 55,90 na Netflix',
        );
        expect(t!.categoriaSugerida, equals('Lazer'));
      });

      test('sugere Outros para estabelecimento desconhecido', () {
        final t = BankNotificationParser.parseNotificacao(
          appPackageOuNome: 'com.nubank',
          titulo: 'Compra',
          texto: 'R\$ 10,00 na Loja XYZ',
        );
        expect(t!.categoriaSugerida, equals('Outros'));
      });
    });

    // ─── Origem ───────────────────────────────────────────────────────────────
    test('origem deve ser notificacaoPush', () {
      final t = BankNotificationParser.parseNotificacao(
        appPackageOuNome: 'com.nubank',
        titulo: 'Compra',
        texto: 'R\$ 10,00 aprovado',
      );
      expect(t!.origem, equals(OrigemTransacaoBancaria.notificacaoPush));
    });
  });
}
