import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/cartoes/domain/cartao_credito.dart';
import 'package:meubolso/features/cartoes/domain/formas_pagamento.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';

final _agora = DateTime(2026, 10, 2);
var _seq = 0;

Lancamento _despesa(String forma, int cents, {bool importado = false}) =>
    Lancamento(
      id: 'l${_seq++}',
      descricao: 'gasto',
      valorCents: cents,
      categoria: 'Outros',
      formaPagamento: forma,
      data: _agora,
      obs: importado ? 'pluggy_id:tx$_seq' : null,
      createdAt: _agora,
      updatedAt: _agora,
    );

CartaoCredito _cartao(String id, String nome) => CartaoCredito(
      id: id,
      nome: nome,
      diaFechamento: 3,
      diaVencimento: 10,
    );

void main() {
  group('formasPagamentoDoUsuario', () {
    test('sem cartões: nenhum cartão de outra pessoa na lista', () {
      final formas = formasPagamentoDoUsuario(const []);
      expect(formas, ['Pix', 'Débito', 'Dinheiro', 'Cartão de Crédito']);
      expect(formas.any((f) => f.contains('Nubank')), isFalse);
    });

    test('um "Cartão: nome" por cartão cadastrado', () {
      final formas = formasPagamentoDoUsuario([_cartao('1', 'Itaú Click')]);
      expect(formas, contains('Cartão: Itaú Click'));
    });

    test('formasComAtual mantém a forma de um importado ao editar', () {
      final formas = formasPagamentoDoUsuario(const []);
      expect(formasComAtual(formas, 'Conta: itau'), contains('Conta: itau'));
      expect(formasComAtual(formas, 'Pix'), formas);
    });
  });

  group('agruparPorFormaPagamento', () {
    test('débito em conta importado soma com o Pix, não vai para cartão', () {
      final grupos = agruparPorFormaPagamento(
        [_despesa('Pix', 4900), _despesa('Conta: itau', 6650)],
        [_cartao('nu', 'Nubank')],
      );
      expect(grupos, hasLength(1));
      expect(grupos.single.tipo, TipoGrupoForma.conta);
      expect(grupos.single.totalCents, 11550);
    });

    test('cartão não cadastrado fica na própria linha (nunca no 1º cartão)',
        () {
      final grupos = agruparPorFormaPagamento(
        [_despesa('Cartão: gold', 132688), _despesa('Cartão: Nubank', 1000)],
        [_cartao('nu', 'Nubank')],
      );
      final gold = grupos.firstWhere((g) => g.titulo == 'Cartão gold');
      expect(gold.totalCents, 132688);
      expect(gold.cartao, isNull);
      expect(gold.nomeNaoCadastrado, 'gold');
      final nubank = grupos.firstWhere((g) => g.cartao?.id == 'nu');
      expect(nubank.totalCents, 1000);
    });

    test('casa nome parecido: "Cartão: Inter" com o cartão "Banco Inter"', () {
      final grupos = agruparPorFormaPagamento(
        [_despesa('Cartão: Inter', 2500)],
        [_cartao('in', 'Banco Inter')],
      );
      expect(grupos.single.cartao?.id, 'in');
      expect(grupos.single.titulo, 'Cartão Banco Inter');
    });

    test('genérico e outras formas em grupos próprios, maior primeiro', () {
      final grupos = agruparPorFormaPagamento(
        [
          _despesa('Cartão de Crédito', 300),
          _despesa('Outro', 900),
          _despesa('Pix', 100),
        ],
        const [],
      );
      expect(grupos.map((g) => g.titulo),
          ['Outras formas', 'Cartão sem nome', 'Pix e débito']);
      expect(grupos[1].nomeNaoCadastrado, isNull);
    });

    test('sem despesas: nenhum grupo', () {
      expect(agruparPorFormaPagamento(const [], const []), isEmpty);
    });
  });

  group('sugestoesDeCartoes', () {
    test('só cartões importados do banco, sem os já cadastrados, mais usado '
        'primeiro', () {
      final sugestoes = sugestoesDeCartoes(
        [
          _despesa('Cartão: gold', 100, importado: true),
          _despesa('Cartão: platinum', 100, importado: true),
          _despesa('Cartão: Gold', 100, importado: true),
          _despesa('Cartão: Nubank', 100, importado: true),
          // Escolhido à mão (ex.: lista antiga com o Nubank do dono): ignora.
          _despesa('Cartão: Inter', 100),
          _despesa('Conta: itau', 100, importado: true),
        ],
        [_cartao('nu', 'Nubank')],
      );
      expect(sugestoes, ['gold', 'platinum']);
    });
  });
}
