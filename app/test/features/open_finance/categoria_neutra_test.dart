import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';

void main() {
  String? classificar({
    String? categoria,
    String descricao = 'Pix recebido',
    Map<String, dynamic>? paymentData,
    bool entrada = true,
  }) =>
      categoriaNeutra(
        categoriaPluggy: categoria,
        descricao: descricao,
        paymentData: paymentData,
        entrada: entrada,
        cpfTitular: '123.456.789-09',
        nomeTitular: 'Leonardo Vieira',
      );

  group('categoriaNeutra', () {
    test('resgate de RDB / caixinha é investimento', () {
      expect(classificar(descricao: 'Resgate RDB'),
          categoriaMovimentacaoInvestimento);
      expect(classificar(descricao: 'Dinheiro guardado na caixinha'),
          categoriaMovimentacaoInvestimento);
      expect(classificar(categoria: 'Investments'),
          categoriaMovimentacaoInvestimento);
    });

    test('Pluggy marca mesma titularidade', () {
      expect(classificar(categoria: 'Same person transfer - PIX'),
          categoriaTransferenciaEntreContas);
    });

    test('entrada paga pelo próprio CPF é transferência entre contas', () {
      expect(
        classificar(paymentData: {
          'payer': {
            'name': 'LEONARDO VIEIRA',
            'documentNumber': {'type': 'CPF', 'value': '12345678909'},
          },
        }),
        categoriaTransferenciaEntreContas,
      );
    });

    test('saída para o próprio nome (sem CPF) é transferência entre contas', () {
      expect(
        classificar(
          entrada: false,
          descricao: 'Pix enviado',
          paymentData: {
            'receiver': {'name': 'leonardo  vieira'},
          },
        ),
        categoriaTransferenciaEntreContas,
      );
    });

    test('venda de ações (B3 / nota Bovespa) é investimento', () {
      expect(classificar(descricao: 'Crédito B3 - Nota Bov 27/05/2026'),
          categoriaMovimentacaoInvestimento);
    });

    test('nome do titular na descrição "Transferência Recebida|NOME"', () {
      expect(classificar(descricao: 'Transferência Recebida|LEONARDO VIEIRA'),
          categoriaTransferenciaEntreContas);
      expect(classificar(descricao: 'Transferência Recebida|OUTRA PESSOA'),
          isNull);
    });

    test('salário vindo de outra pessoa/empresa continua sendo entrada', () {
      expect(
        classificar(
          descricao: 'Transferência recebida',
          paymentData: {
            'payer': {
              'name': 'EMPRESA X LTDA',
              'documentNumber': {'type': 'CNPJ', 'value': '11222333000181'},
            },
          },
        ),
        isNull,
      );
    });
  });
}
