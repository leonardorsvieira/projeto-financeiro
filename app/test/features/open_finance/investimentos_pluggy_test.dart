import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meubolso/core/edge_function.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';

import '../../support/fake_investimentos_repository.dart';

final _funcao = EdgeFunction(
  url: Uri.parse('https://exemplo.supabase.co/functions/v1/pluggy'),
  anonKey: 'anon-teste',
  tokenDeAcesso: () async => 'token-usuario',
);

ContaBancariaConectada _conta(String itemId) => ContaBancariaConectada(
      id: itemId,
      nomeBanco: 'Banco',
      tipoConta: 'Conta',
      corHex: '#000000',
      ultimoSync: DateTime(2026, 9, 29),
      status: StatusConexaoBanco.conectado,
      itemIdPluggy: itemId,
    );

void main() {
  group('investimentoDaPluggy', () {
    test('renda fixa usa o saldo e junta o emissor ao nome', () {
      final inv = investimentoDaPluggy({
        'id': 'p1',
        'type': 'FIXED_INCOME',
        'subtype': 'CDB',
        'name': 'CDB 110% CDI',
        'issuer': 'Banco X',
        'balance': 1234.56,
        'status': 'ACTIVE',
      })!;
      expect(inv.classe, TipoClasseInvestimento.rendaFixa);
      expect(inv.nome, 'CDB 110% CDI · Banco X');
      expect(inv.saldoCents, 123456);
      expect(inv.patrimonioCents, 123456);
      expect(inv.pluggyId, 'p1');
    });

    test('ação usa ticker, quantidade e preço unitário', () {
      final inv = investimentoDaPluggy({
        'id': 'p2',
        'type': 'EQUITY',
        'subtype': 'STOCK',
        'code': 'PETR4',
        'name': 'Petrobras PN',
        'quantity': 10,
        'value': 38.5,
        'balance': 385,
      })!;
      expect(inv.classe, TipoClasseInvestimento.acao);
      expect(inv.nome, 'PETR4');
      expect(inv.quantidade, 10);
      expect(inv.precoAtualCents, 3850);
      expect(inv.patrimonioCents, 38500);
    });

    test('FII sem quantidade vira 1 unidade com o saldo inteiro', () {
      final inv = investimentoDaPluggy({
        'id': 'p3',
        'type': 'EQUITY',
        'subtype': 'REAL_ESTATE_FUND',
        'code': 'HGLG11',
        'balance': 500,
      })!;
      expect(inv.classe, TipoClasseInvestimento.fii);
      expect(inv.patrimonioCents, 50000);
    });

    test('ignora resgatados e saldo zerado', () {
      expect(
        investimentoDaPluggy({
          'id': 'p4',
          'type': 'FIXED_INCOME',
          'balance': 100,
          'status': 'TOTAL_WITHDRAWAL',
        }),
        isNull,
      );
      expect(
        investimentoDaPluggy({'id': 'p5', 'type': 'MUTUAL_FUND', 'balance': 0}),
        isNull,
      );
    });
  });

  group('buscarInvestimentos', () {
    test('pagina por item e marca incompleto quando um item falha', () async {
      final pedidos = <String>[];
      final service = PluggyOpenFinanceService(
        funcao: _funcao,
        httpClient: MockClient((request) async {
          final env = jsonDecode(request.body) as Map<String, dynamic>;
          final caminho = Uri.parse(env['caminho'] as String);
          expect(caminho.path, '/investments');
          final item = caminho.queryParameters['itemId']!;
          final pagina = caminho.queryParameters['page']!;
          pedidos.add('$item:$pagina');
          if (item == 'item_ruim') return http.Response('{}', 403);
          return http.Response(
            jsonEncode({
              'totalPages': 2,
              'results': [
                {
                  'id': 'inv_$pagina',
                  'type': 'FIXED_INCOME',
                  'name': 'Tesouro',
                  'balance': 10,
                },
              ],
            }),
            200,
          );
        }),
      );

      final ok = await service.buscarInvestimentos([_conta('item_ok')]);
      expect(ok.completo, isTrue);
      expect(ok.investimentos.map((i) => i.pluggyId), ['inv_1', 'inv_2']);

      final parcial = await service
          .buscarInvestimentos([_conta('item_ok'), _conta('item_ruim')]);
      expect(parcial.completo, isFalse);
      expect(parcial.investimentos, hasLength(2));
      expect(pedidos, contains('item_ruim:1'));
    });
  });

  group('sincronizarOpenFinance (fake)', () {
    test('atualiza importados, remove ausentes e preserva manuais', () async {
      final repo = FakeInvestimentosRepository([
        const Investimento(
          id: 'manual',
          classe: TipoClasseInvestimento.rendaFixa,
          nome: 'Poupança',
          saldoCents: 100,
        ),
        const Investimento(
          id: 'antigo',
          classe: TipoClasseInvestimento.rendaFixa,
          nome: 'CDB resgatado',
          saldoCents: 100,
          pluggyId: 'sumiu',
        ),
      ]);
      await repo.sincronizarOpenFinance(
        [
          const Investimento(
            id: '',
            classe: TipoClasseInvestimento.rendaFixa,
            nome: 'LCI',
            saldoCents: 5000,
            pluggyId: 'novo',
          ),
        ],
        removerAusentes: true,
      );
      expect(repo.items.map((i) => i.id), ['manual', 'inv-pluggy-novo']);
    });
  });
}
