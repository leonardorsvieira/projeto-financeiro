import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/consultoria/application/dados_consultoria.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';

Lancamento _lanc(
  String id,
  int valorCents,
  DateTime data, {
  String categoria = 'Outros',
  TipoLancamento tipo = TipoLancamento.despesa,
  String descricao = 'descrição secreta',
}) {
  return Lancamento(
    id: id,
    descricao: descricao,
    categoria: categoria,
    valorCents: valorCents,
    formaPagamento: 'Pix',
    data: data,
    tipo: tipo,
    createdAt: data,
    updatedAt: data,
  );
}

void main() {
  final hoje = DateTime(2026, 10, 3);

  group('montarDadosConsultoria', () {
    test('média dos últimos 3 meses completos, sem o mês atual', () {
      final dados = montarDadosConsultoria(
        lancamentos: [
          for (final m in [7, 8, 9]) ...[
            _lanc('r$m', 500000, DateTime(2026, m, 5),
                tipo: TipoLancamento.receita),
            _lanc('m$m', 200000, DateTime(2026, m, 10), categoria: 'Moradia'),
          ],
          _lanc('a9', 100000, DateTime(2026, 9, 12), categoria: 'Alimentação'),
          // Mês atual (parcial) e mês antigo ficam fora da média.
          _lanc('atual', 999900, DateTime(2026, 10, 2), categoria: 'Lazer'),
          _lanc('antigo', 888800, DateTime(2026, 5, 2), categoria: 'Lazer'),
          // Transferência entre contas próprias não é gasto.
          _lanc('transf', 777700, DateTime(2026, 9, 3),
              categoria: categoriaTransferenciaEntreContas),
        ],
        investimentos: const [],
        contas: const [],
        hoje: hoje,
      );

      expect(dados.meses, [
        DateTime(2026, 7),
        DateTime(2026, 8),
        DateTime(2026, 9),
      ]);
      expect(dados.mesParcial, isFalse);
      expect(dados.receitaMediaCents, 500000);
      // (200000 × 3 + 100000) / 3
      expect(dados.despesaMediaCents, 233333);
      expect(dados.sobraMediaCents, 266667);
      expect(dados.categoriasMedias.first.categoria, 'Moradia');
      expect(dados.categoriasMedias.first.valorCents, 200000);
      expect(
        dados.categoriasMedias.map((c) => c.categoria),
        isNot(contains('Lazer')),
      );
    });

    test('mês sem lançamentos não entra na média', () {
      final dados = montarDadosConsultoria(
        lancamentos: [
          _lanc('s', 300000, DateTime(2026, 9, 5)),
        ],
        investimentos: const [],
        contas: const [],
        hoje: hoje,
      );
      expect(dados.meses, [DateTime(2026, 9)]);
      expect(dados.despesaMediaCents, 300000);
    });

    test('sem mês completo usa o mês atual como parcial', () {
      final dados = montarDadosConsultoria(
        lancamentos: [_lanc('x', 5000, DateTime(2026, 10, 1))],
        investimentos: const [],
        contas: const [],
        hoje: hoje,
      );
      expect(dados.meses, [DateTime(2026, 10)]);
      expect(dados.mesParcial, isTrue);
      expect(dados.paraPrompt(), contains('(parcial)'));
    });

    test('reserva = contas + renda fixa + banco digital, em meses', () {
      final dados = montarDadosConsultoria(
        lancamentos: [_lanc('d', 200000, DateTime(2026, 9, 1))],
        investimentos: const [
          Investimento(
            id: '1',
            classe: TipoClasseInvestimento.rendaFixa,
            nome: 'CDB Liquidez Diária',
            saldoCents: 500000,
            valorInvestidoCents: 450000,
          ),
          Investimento(
            id: '2',
            classe: TipoClasseInvestimento.acao,
            nome: 'ABCD3',
            quantidade: 10,
            precoAtualCents: 3000,
          ),
        ],
        contas: [
          ContaBancariaConectada(
            id: 'c',
            nomeBanco: 'Banco',
            tipoConta: 'Conta',
            corHex: '#000000',
            ultimoSync: DateTime(2026, 10, 2, 9),
            saldoContasCents: 100000,
            faturaCartoesCents: 80000,
          ),
        ],
        hoje: hoje,
      );

      expect(dados.investidoCents, 530000);
      expect(dados.reservaCents, 600000); // 1.000 + 5.000 (ação fora)
      expect(dados.mesesDeReserva, 3);
      expect(dados.faturasAbertasCents, 80000);

      final texto = dados.paraPrompt();
      expect(texto, contains('Saldo nas contas dos bancos conectados: R\$ 1.000,00'));
      expect(texto, contains('Faturas de cartão em aberto: R\$ 800,00'));
      expect(texto, contains('Renda Fixa: R\$ 5.000,00'));
      expect(texto, contains('CDB Liquidez Diária R\$ 5.000,00 (+11,1% desde'));
      expect(texto, contains('Ações: R\$ 300,00'));
      expect(texto, contains('= 3,0 meses das despesas médias'));
    });

    test('o texto para a IA não leva descrições de lançamentos', () {
      final dados = montarDadosConsultoria(
        lancamentos: [
          _lanc('d', 12345, DateTime(2026, 9, 1),
              descricao: 'Pix para Fulano de Tal', categoria: 'Lazer'),
        ],
        investimentos: const [],
        contas: const [],
        hoje: hoje,
      );
      final texto = dados.paraPrompt();
      expect(texto, isNot(contains('Fulano')));
      expect(texto, contains('Lazer: R\$ 123,45'));
      expect(texto, contains('Bancos conectados: nenhum'));
      expect(texto, contains('Investimentos: nenhum registrado.'));
    });

    test('sem nada registrado', () {
      final dados = montarDadosConsultoria(
        lancamentos: const [],
        investimentos: const [],
        contas: const [],
        hoje: hoje,
      );
      expect(dados.semDados, isTrue);
      expect(dados.mesesDeReserva, isNull);
      expect(dados.paraPrompt(), contains('nenhum lançamento registrado'));
    });
  });
}
