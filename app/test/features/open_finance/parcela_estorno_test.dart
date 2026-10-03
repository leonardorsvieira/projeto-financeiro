import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/dashboard/application/dashboard_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/open_finance/application/open_finance_providers.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/transacao_bancaria_importada.dart';

Lancamento _lanc(
  int cents, {
  TipoLancamento tipo = TipoLancamento.despesa,
  String forma = 'Cartão: Mercado Pago',
  DateTime? data,
}) {
  final d = data ?? DateTime(2026, 9, 9);
  return Lancamento(
    id: '$cents$forma$tipo',
    descricao: 'x',
    valorCents: cents,
    categoria: 'Compras',
    formaPagamento: forma,
    data: d,
    tipo: tipo,
    createdAt: d,
    updatedAt: d,
  );
}

TransacaoBancariaImportada _tx(String descricao, String? doBanco) =>
    TransacaoBancariaImportada(
      id: 't1',
      nomeBanco: 'Mercado Pago',
      descricao: descricao,
      descricaoDoBanco: doBanco,
      valorCents: 4311,
      isReceita: false,
      formaPagamento: 'Cartão: Mercado Pago',
      data: DateTime(2026, 9, 9),
      origem: OrigemTransacaoBancaria.openFinance,
    );

void main() {
  group('descricaoComParcela', () {
    test('compra parcelada ganha o número da parcela', () {
      expect(
        descricaoComParcela('MERCADOLIVRE*MERCADOLIVRE', {
          'installmentNumber': 2,
          'totalInstallments': 8,
        }),
        'MERCADOLIVRE*MERCADOLIVRE (2/8)',
      );
    });

    test('à vista, sem metadado ou banco que já põe o número: igual', () {
      expect(
        descricaoComParcela('PADARIA', {
          'installmentNumber': 1,
          'totalInstallments': 1,
        }),
        'PADARIA',
      );
      expect(descricaoComParcela('PADARIA', null), 'PADARIA');
      expect(
        descricaoComParcela('LOJA X PARC 02/08', {
          'installmentNumber': 2,
          'totalInstallments': 8,
        }),
        'LOJA X PARC 02/08',
      );
    });

    test('cabe nos 200 caracteres sem perder o número', () {
      final longa = 'A' * 250;
      final d = descricaoComParcela(longa, {
        'installmentNumber': 10,
        'totalInstallments': 12,
      });
      expect(d.length, 200);
      expect(d, endsWith(' (10/12)'));
      expect(descricaoComParcela(longa, null).length, 200);
    });
  });

  group('precisaRenomearImportado', () {
    final tx = _tx('MERCADOLIVRE (2/8)', 'MERCADOLIVRE');

    test('importado com a descrição do banco: renomeia', () {
      expect(precisaRenomearImportado(tx, 'MERCADOLIVRE'), isTrue);
    });

    test('editado pelo usuário, já renomeado ou sem parcela: não mexe', () {
      expect(precisaRenomearImportado(tx, 'Fone de ouvido'), isFalse);
      expect(precisaRenomearImportado(tx, 'MERCADOLIVRE (2/8)'), isFalse);
      expect(
        precisaRenomearImportado(_tx('PADARIA', 'PADARIA'), 'PADARIA'),
        isFalse,
      );
    });
  });

  group('estorno de cartão', () {
    test('entrada no cartão é estorno; Pix recebido é receita', () {
      final estorno = _lanc(34490, tipo: TipoLancamento.receita);
      final generico = _lanc(
        100,
        tipo: TipoLancamento.receita,
        forma: 'Cartão de Crédito',
      );
      final pix = _lanc(500000, tipo: TipoLancamento.receita, forma: 'Pix');

      expect(estorno.ehEstornoDeCartao, isTrue);
      expect(estorno.valorDespesaCents, -34490);
      expect(generico.ehEstornoDeCartao, isTrue);
      expect(pix.ehEstornoDeCartao, isFalse);
      expect(pix.valorDespesaCents, 0);
      expect(_lanc(4311).valorDespesaCents, 4311);
    });

    test('abate as saídas do mês em vez de virar receita', () {
      final r = resumoDoMes([
        _lanc(500000, tipo: TipoLancamento.receita, forma: 'Pix'),
        _lanc(4313, data: DateTime(2026, 9, 1)),
        _lanc(4311),
        _lanc(50000, forma: 'Pix'),
        _lanc(34490, tipo: TipoLancamento.receita, data: DateTime(2026, 9, 7)),
      ], DateTime(2026, 9));

      expect(r.entradasCents, 500000, reason: 'estorno não é renda');
      // 43,13 + 43,11 + 500 − 344,90
      expect(r.saidasCents, 24134);
      // O saldo não muda: 5000 − 241,34.
      expect(r.saldoCents, 475866);
    });
  });
}
