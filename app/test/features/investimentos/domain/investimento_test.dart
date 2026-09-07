import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/investimentos/domain/investimento.dart';

void main() {
  group('TipoClasseInvestimento', () {
    test('dbValue/rotulo/ePorQuantidade corretos', () {
      expect(TipoClasseInvestimento.acao.dbValue, 'acao');
      expect(TipoClasseInvestimento.acao.ePorQuantidade, isTrue);
      expect(TipoClasseInvestimento.fii.ePorQuantidade, isTrue);
      expect(TipoClasseInvestimento.cripto.ePorQuantidade, isTrue);
      expect(TipoClasseInvestimento.rendaFixa.ePorQuantidade, isFalse);
      expect(TipoClasseInvestimento.bancoDigital.ePorQuantidade, isFalse);
      expect(TipoClasseInvestimento.rendaFixa.rotulo, 'Renda Fixa');
    });

    test('fromDb mapeia e tem fallback', () {
      expect(
        TipoClasseInvestimento.fromDb('renda_fixa'),
        TipoClasseInvestimento.rendaFixa,
      );
      expect(
        TipoClasseInvestimento.fromDb('desconhecido'),
        TipoClasseInvestimento.acao,
      );
    });
  });

  group('Investimento.patrimonioCents', () {
    test('por quantidade = qtd × preço', () {
      const inv = Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 3850,
      );
      expect(inv.ePorQuantidade, isTrue);
      expect(inv.patrimonioCents, 38500);
    });

    test('por saldo = saldo', () {
      const inv = Investimento(
        id: 'i2',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'CDB',
        saldoCents: 50000,
      );
      expect(inv.ePorQuantidade, isFalse);
      expect(inv.patrimonioCents, 50000);
    });
  });

  group('Investimento.fromMap/toMap', () {
    test('roundtrip por quantidade', () {
      const inv = Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.cripto,
        nome: 'BTC',
        quantidade: 0.5,
        precoAtualCents: 40000000,
      );
      final fromMap = Investimento.fromMap(inv.toMap());
      expect(fromMap.id, inv.id);
      expect(fromMap.classe, inv.classe);
      expect(fromMap.nome, inv.nome);
      expect(fromMap.quantidade, inv.quantidade);
      expect(fromMap.precoAtualCents, inv.precoAtualCents);
      expect(fromMap.saldoCents, inv.saldoCents);
    });

    test('fromMap aceita números como num', () {
      final inv = Investimento.fromMap({
        'id': 'i3',
        'classe': 'banco_digital',
        'nome': 'Nubank',
        'quantidade': 0,
        'preco_atual_cents': 0,
        'saldo_cents': 12340,
      });
      expect(inv.classe, TipoClasseInvestimento.bancoDigital);
      expect(inv.saldoCents, 12340);
    });
  });
}
