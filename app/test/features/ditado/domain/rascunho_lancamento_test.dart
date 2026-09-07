import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

void main() {
  group('RascunhoLancamento.fromJson', () {
    test('preenche todos os campos', () {
      final rascunho = RascunhoLancamento.fromJson({
        'descricao': 'Almoço',
        'valor_reais': '42,90',
        'categoria': 'Alimentação',
        'forma_pagamento': 'Pix',
        'data': '2026-09-06',
        'vencimento': '2026-09-12',
        'tipo': 'receita',
      });

      expect(rascunho.descricao, 'Almoço');
      expect(rascunho.valorTexto, '42,90');
      expect(rascunho.categoria, 'Alimentação');
      expect(rascunho.formaPagamento, 'Pix');
      expect(rascunho.dataIso, '2026-09-06');
      expect(rascunho.vencimentoIso, '2026-09-12');
      expect(rascunho.tipo, 'receita');
    });

    test('deixa tipo null quando ausente', () {
      final rascunho = RascunhoLancamento.fromJson({
        'descricao': 'Almoço',
      });

      expect(rascunho.tipo, isNull);
    });

    test('deixa null campos ausentes ou vazios', () {
      final rascunho = RascunhoLancamento.fromJson({
        'descricao': '',
        'valor_reais': '  ',
        'categoria': null,
      });

      expect(rascunho.descricao, isNull);
      expect(rascunho.valorTexto, isNull);
      expect(rascunho.categoria, isNull);
      expect(rascunho.formaPagamento, isNull);
      expect(rascunho.dataIso, isNull);
      expect(rascunho.vencimentoIso, isNull);
    });

    test('aparar espaços em branco das bordas', () {
      final rascunho = RascunhoLancamento.fromJson({
        'descricao': '  Uber  ',
        'valor_reais': ' 25,00 ',
      });

      expect(rascunho.descricao, 'Uber');
      expect(rascunho.valorTexto, '25,00');
    });
  });

  group('RascunhoLancamento.corrigir', () {
    RascunhoLancamento base() => const RascunhoLancamento(
          descricao: 'Uber',
          valorTexto: '25,00',
          categoria: 'Transporte',
          formaPagamento: 'Pix',
          dataIso: '2026-09-06',
          vencimentoIso: null,
        );

    test('corrige descricao preservando o resto', () {
      final novo = base().corrigir(CampoDitado.descricao, 'Uber ida ao médico');

      expect(novo.descricao, 'Uber ida ao médico');
      expect(novo.valorTexto, '25,00');
      expect(novo.categoria, 'Transporte');
      expect(novo.formaPagamento, 'Pix');
      expect(novo.dataIso, '2026-09-06');
    });

    test('corrige valor', () {
      final novo = base().corrigir(CampoDitado.valor, '30,50');
      expect(novo.valorTexto, '30,50');
      expect(novo.descricao, 'Uber');
    });

    test('corrige categoria', () {
      final novo = base().corrigir(CampoDitado.categoria, 'Saúde');
      expect(novo.categoria, 'Saúde');
      expect(novo.formaPagamento, 'Pix');
    });

    test('corrige forma de pagamento', () {
      final novo = base().corrigir(CampoDitado.formaPagamento, 'Cartão de Crédito');
      expect(novo.formaPagamento, 'Cartão de Crédito');
    });

    test('corrige data e vencimento', () {
      final comVenc = base().corrigir(CampoDitado.vencimento, '2026-09-12');
      expect(comVenc.vencimentoIso, '2026-09-12');

      final novaData = base().corrigir(CampoDitado.data, '2026-09-07');
      expect(novaData.dataIso, '2026-09-07');
      expect(novaData.vencimentoIso, isNull);
    });

    test('corrige tipo preservando o resto', () {
      final baseReceita = RascunhoLancamento(
        descricao: 'Salário',
        valorTexto: '3000,00',
        categoria: 'Outros',
        formaPagamento: 'Pix',
        dataIso: '2026-09-06',
        vencimentoIso: null,
        tipo: 'despesa',
      );

      final nova = baseReceita.corrigir(CampoDitado.tipo, 'receita');
      expect(nova.tipo, 'receita');
      expect(nova.descricao, 'Salário');
      expect(nova.valorTexto, '3000,00');

      final outro = base().corrigir(CampoDitado.tipo, null);
      expect(outro.tipo, isNull);
    });

    test('corrigir descrição preserva o tipo', () {
      final novo = RascunhoLancamento(
        descricao: 'S',
        valorTexto: null,
        tipo: 'receita',
      ).corrigir(CampoDitado.descricao, 'Salário');

      expect(novo.descricao, 'Salário');
      expect(novo.tipo, 'receita');
    });

    test('limpa campo com valor null', () {
      final novo = base().corrigir(CampoDitado.valor, null);
      expect(novo.valorTexto, isNull);
    });
  });

  group('RascunhoLancamento.toJson', () {
    test('roundtrip preserva valores', () {
      const rascunho = RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
        dataIso: '2026-09-06',
        vencimentoIso: null,
      );

      expect(rascunho.toJson(), {
        'descricao': 'Almoço',
        'valor_reais': '42,90',
        'categoria': 'Alimentação',
        'forma_pagamento': 'Pix',
        'data': '2026-09-06',
        'vencimento': null,
        'tipo': null,
      });
    });

    test('roundtrip preserva tipo receita', () {
      const rascunho = RascunhoLancamento(
        descricao: 'Salário',
        valorTexto: '3000,00',
        categoria: 'Outros',
        tipo: 'receita',
      );

      expect(rascunho.toJson()['tipo'], 'receita');
    });
  });
}