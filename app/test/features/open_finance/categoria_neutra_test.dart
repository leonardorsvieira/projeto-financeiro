import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/contas_proprias.dart';

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

    test('recarga de celular nunca é transferência, mesmo com o CPF do titular',
        () {
      expect(
        classificar(
          descricao: 'Recarga - Claro',
          entrada: false,
          paymentData: {
            'receiver': {
              'name': 'LEONARDO VIEIRA',
              'documentNumber': {'type': 'CPF', 'value': '12345678909'},
            },
          },
        ),
        isNull,
      );
    });

    test('conta no nome de outra pessoa marcada como própria é transferência',
        () {
      String? comProprias(String descricao, {Map<String, dynamic>? pd}) =>
          categoriaNeutra(
            categoriaPluggy: null,
            descricao: descricao,
            paymentData: pd,
            entrada: false,
            cpfTitular: '123.456.789-09',
            nomeTitular: 'Gabriel Vieira',
            nomesProprios: const ['Lorena Alves De Jesus Vieira'],
          );

      expect(comProprias('Pix enviado  - Lorena Alves de Jesus Vieira'),
          categoriaTransferenciaEntreContas);
      expect(
        comProprias('Pix enviado', pd: {
          'receiver': {'name': 'LORENA ALVES DE JESUS VIEIRA'},
        }),
        categoriaTransferenciaEntreContas,
      );
      // Outra pessoa continua sendo gasto.
      expect(comProprias('Pix enviado  - Lorena Souza'), isNull);
    });
  });

  group('contas próprias', () {
    test('contraparteDaDescricao pega o nome no fim da descrição', () {
      expect(contraparteDaDescricao('Pix enviado  - Lorena Alves'),
          'Lorena Alves');
      expect(contraparteDaDescricao('Transferência Recebida|JOAO SILVA'),
          'JOAO SILVA');
      expect(contraparteDaDescricao('Pix enviado'), isNull);
    });

    test('ehContaPropria ignora maiúsculas e espaços', () {
      expect(ehContaPropria(['Lorena  Vieira'], ['LORENA VIEIRA']), isTrue);
      expect(ehContaPropria(const [], ['LORENA VIEIRA']), isFalse);
      expect(ehContaPropria(['Lorena Vieira'], [null, 'Outra']), isFalse);
    });
  });

  group('saldosDasContasPluggy', () {
    test('soma saldo das contas e fatura dos cartões separadamente', () {
      final (saldo, fatura) = saldosDasContasPluggy([
        {'type': 'BANK', 'balance': 1500.25},
        {'type': 'BANK', 'balance': -100},
        {'type': 'CREDIT', 'balance': 820.10},
        {'type': 'BANK'}, // sem saldo informado
      ]);
      expect(saldo, 140025);
      expect(fatura, 82010);
    });

    test('sem nenhuma conta com saldo: null (não inventa zero)', () {
      final (saldo, fatura) = saldosDasContasPluggy([
        {'type': 'BANK'},
      ]);
      expect(saldo, isNull);
      expect(fatura, isNull);
    });
  });
}
