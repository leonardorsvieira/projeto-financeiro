import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';
import 'package:meubolso/features/open_finance/domain/fatura_cartao.dart';

var _seq = 0;

Lancamento _lanc(
  String forma,
  int cents,
  DateTime data, {
  bool estorno = false,
  String categoria = 'Outros',
}) =>
    Lancamento(
      id: 'l${_seq++}',
      descricao: 'x',
      valorCents: cents,
      categoria: categoria,
      formaPagamento: forma,
      data: data,
      tipo: estorno ? TipoLancamento.receita : TipoLancamento.despesa,
      createdAt: data,
      updatedAt: data,
    );

void main() {
  // Fatura de setembro fechou em 05/09 (vence 12/09); a de outubro, em 05/10
  // (vence 12/10). Hoje: 03/10 → a de outubro ainda não fechou.
  final gold = CartaoOpenFinance(
    formasPagamento: const ['Cartão: gold', 'Cartão: Itaú'],
    faturas: [
      FaturaCartao(
        vencimento: DateTime(2026, 9, 12),
        fechamento: DateTime(2026, 9, 5),
        valorCents: 180000,
      ),
      FaturaCartao(
        vencimento: DateTime(2026, 8, 12),
        fechamento: DateTime(2026, 8, 5),
        valorCents: 210000,
      ),
    ],
  );
  final agora = DateTime(2026, 10, 3, 15);
  final lancamentos = [
    _lanc('Cartão: gold', 30000, DateTime(2026, 9, 4)), // fatura de setembro
    _lanc('Cartão: gold', 50000, DateTime(2026, 9, 5)), // aberta
    _lanc('Cartão: GOLD', 20000, DateTime(2026, 9, 20)), // webhook, maiúscula
    _lanc('Cartão: Itaú', 10000, DateTime(2026, 10, 1)), // outra grafia
    _lanc('Cartão: gold', 5000, DateTime(2026, 9, 25), estorno: true),
    _lanc('Cartão: gold', 99999, DateTime(2026, 11, 5)), // parcela futura
    _lanc('Cartão: gold', 7777, DateTime(2026, 9, 21),
        categoria: categoriaMovimentacaoInvestimento),
    _lanc('Cartão: Nubank', 12345, DateTime(2026, 9, 22)), // outro cartão
  ];

  group('faturasDoMes', () {
    test('mês com fatura fechada: o valor que o banco informou', () {
      final f = faturasDoMes(
        cartoes: [gold],
        lancamentos: lancamentos,
        mes: DateTime(2026, 9),
        agora: agora,
      ).single;

      expect(f.valorCents, 180000);
      expect(f.aberta, isFalse);
      expect(f.vencimento, DateTime(2026, 9, 12));
      expect(f.formasPagamento, ['Cartão: gold', 'Cartão: Itaú']);
    });

    test('mês seguinte à última fechada: fatura aberta até hoje', () {
      final f = faturasDoMes(
        cartoes: [gold],
        lancamentos: lancamentos,
        mes: DateTime(2026, 10),
        agora: agora,
      ).single;

      // 500 + 200 + 100 − 50 de estorno; sem a compra antes do fechamento,
      // a parcela futura, a aplicação e o outro cartão.
      expect(f.valorCents, 75000);
      expect(f.aberta, isTrue);
      expect(f.vencimento, DateTime(2026, 10, 12));
    });

    test('sem data de fechamento: corta 7 dias antes do vencimento', () {
      final semFechamento = CartaoOpenFinance(
        formasPagamento: const ['Cartão: gold'],
        faturas: [
          FaturaCartao(vencimento: DateTime(2026, 9, 12), valorCents: 1),
        ],
      );
      final f = faturasDoMes(
        cartoes: [semFechamento],
        lancamentos: lancamentos,
        mes: DateTime(2026, 10),
        agora: agora,
      ).single;
      // A partir de 05/09: 500 + 200 − 50.
      expect(f.valorCents, 65000);
    });

    test('meses sem fatura (antigos ou futuros) e cartão sem faturas: nada',
        () {
      for (final mes in [DateTime(2026, 7), DateTime(2026, 11)]) {
        expect(
          faturasDoMes(
            cartoes: [gold],
            lancamentos: lancamentos,
            mes: mes,
            agora: agora,
          ),
          isEmpty,
        );
      }
      expect(
        faturasDoMes(
          cartoes: const [CartaoOpenFinance(formasPagamento: ['Cartão: x'])],
          lancamentos: lancamentos,
          mes: DateTime(2026, 10),
          agora: agora,
        ),
        isEmpty,
      );
    });

    test('vencimento no dia 31 vira o último dia do mês seguinte', () {
      final f = faturasDoMes(
        cartoes: [
          CartaoOpenFinance(
            formasPagamento: const ['Cartão: gold'],
            faturas: [
              FaturaCartao(vencimento: DateTime(2026, 1, 31), valorCents: 1),
            ],
          ),
        ],
        lancamentos: const [],
        mes: DateTime(2026, 2),
        agora: DateTime(2026, 2, 10),
      ).single;
      expect(f.vencimento, DateTime(2026, 2, 28));
    });
  });

  group('fatura aberta pelo banco (billId)', () {
    Map<String, dynamic> tx(
      String data,
      double amount, {
      String? bill,
      String descricao = 'MERCADOLIVRE',
    }) =>
        {
          'date': '${data}T12:00:00.000Z',
          'amount': amount,
          'description': descricao,
          'creditCardMetadata': {'billId': ?bill},
        };

    // Caso real do Mercado Pago (2026-10-03): o banco mostra R$ 217,00.
    final transacoes = [
      tx('2026-09-07', -344.90, bill: 'fatura-set'), // estorno
      tx('2026-09-09', 43.11, bill: 'fatura-set'), // 2ª parcela
      tx('2026-09-16', -500, descricao: 'Pagamento recebido'), // pagou a fatura
      tx('2026-09-17', 216, descricao: 'BARATAO DO CELULAR'),
      tx('2026-09-17', 1, descricao: 'RealizaImportados'),
      tx('2026-11-04', 216, descricao: 'BARATAO DO CELUL'), // parcela futura
    ];

    test('soma só o que ainda não tem fatura, até o vencimento', () {
      expect(
        faturaAbertaDasTransacoes(transacoes, ate: DateTime(2026, 10, 15)),
        21700,
      );
    });

    test('banco sem billId: null (o app estima pelas datas)', () {
      expect(
        faturaAbertaDasTransacoes(
          [tx('2026-09-17', 216), tx('2026-09-20', 10)],
          ate: DateTime(2026, 10, 15),
        ),
        isNull,
      );
      expect(
        faturaAbertaDasTransacoes(const [], ate: DateTime(2026, 10, 15)),
        isNull,
      );
    });

    test('faturasDoMes usa a fatura aberta do banco quando existe', () {
      final comBanco = CartaoOpenFinance(
        formasPagamento: gold.formasPagamento,
        faturas: gold.faturas,
        faturaAbertaCents: 21700,
      );
      final f = faturasDoMes(
        cartoes: [comBanco],
        lancamentos: lancamentos,
        mes: DateTime(2026, 10),
        agora: agora,
      ).single;
      expect(f.valorCents, 21700);
      expect(f.aberta, isTrue);
    });
  });

  group('faturasDaPluggy', () {
    test('lê vencimento e fechamento sem fuso e o total em centavos', () {
      final faturas = faturasDaPluggy([
        {
          'id': 'b1',
          'dueDate': '2026-09-12T00:00:00.000Z',
          'billClosingDate': '2026-09-05T00:00:00.000Z',
          'totalAmount': 1800.5,
        },
        {
          'id': 'b2',
          'dueDate': '2026-10-12T00:00:00.000Z',
          'totalAmount': 950,
        },
        {'id': 'sem-total', 'dueDate': '2026-08-12T00:00:00.000Z'},
      ]);

      expect(faturas, hasLength(2));
      expect(faturas.first.vencimento, DateTime(2026, 10, 12));
      expect(faturas.first.fechamento, isNull);
      expect(faturas.last.vencimento, DateTime(2026, 9, 12));
      expect(faturas.last.fechamento, DateTime(2026, 9, 5));
      expect(faturas.last.valorCents, 180050);
    });
  });

  test('nomeBancoDaConta: nome da conta no Meu Pluggy, senão o da conexão',
      () {
    expect(nomeBancoDaConta('MeuPluggy', 'gold'), 'gold');
    expect(nomeBancoDaConta('Banco Inter', 'Inter'), 'Inter');
    expect(nomeBancoDaConta('Santander', 'SANTANDER SX MASTER'), 'Santander');
    expect(nomeBancoDaConta('Nubank', null), 'Nubank');
  });

  test('ContaBancariaConectada guarda e lê os cartões com as faturas', () {
    final conta = ContaBancariaConectada(
      id: 'i1',
      nomeBanco: 'Itaú',
      tipoConta: 'Cartão',
      corHex: '#000000',
      ultimoSync: DateTime(2026, 10, 3),
      cartoes: [
        CartaoOpenFinance(
          formasPagamento: gold.formasPagamento,
          faturas: gold.faturas,
          faturaAbertaCents: 21700,
        ),
      ],
    );
    final lida = ContaBancariaConectada.fromMap(conta.toMap());

    expect(lida.cartoes.single.formasPagamento, gold.formasPagamento);
    expect(lida.cartoes.single.faturaAbertaCents, 21700);
    expect(lida.cartoes.single.faturas.first.vencimento, DateTime(2026, 9, 12));
    expect(lida.cartoes.single.faturas.first.fechamento, DateTime(2026, 9, 5));
    expect(lida.cartoes.single.faturas.first.valorCents, 180000);
    // Conexões salvas antes desta versão não têm a chave.
    final antiga = conta.toMap()..remove('cartoes');
    expect(ContaBancariaConectada.fromMap(antiga).cartoes, isEmpty);
  });
}
