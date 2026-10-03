import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/dashboard/presentation/dashboard_screen.dart'
    show textoAtualizacaoSaldo;
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';
import 'package:meubolso/features/open_finance/domain/saldo_nas_contas.dart';

ContaBancariaConectada _conta(
  String nome, {
  int? saldo,
  int? fatura,
  required DateTime sync,
}) =>
    ContaBancariaConectada(
      id: nome,
      nomeBanco: nome,
      tipoConta: 'Conta',
      corHex: '#000000',
      ultimoSync: sync,
      saldoContasCents: saldo,
      faturaCartoesCents: fatura,
    );

void main() {
  group('saldoNasContas', () {
    test('soma o saldo de cada banco e usa a atualização mais antiga', () {
      final s = saldoNasContas([
        _conta('Nubank', saldo: 150000, sync: DateTime(2026, 10, 3, 9)),
        _conta('Inter', saldo: -2000, sync: DateTime(2026, 10, 2, 18)),
      ])!;

      expect(s.totalCents, 148000);
      expect(s.porBanco.map((b) => b.nomeBanco), ['Nubank', 'Inter']);
      expect(s.atualizadoEm, DateTime(2026, 10, 2, 18));
    });

    test('ignora conexão sem saldo (ex.: só cartão) e não soma fatura', () {
      final s = saldoNasContas([
        _conta('Nubank', saldo: 50000, fatura: 90000, sync: DateTime(2026, 10, 3)),
        _conta('Cartão XP', fatura: 30000, sync: DateTime(2026, 9, 1)),
      ])!;

      expect(s.totalCents, 50000);
      expect(s.porBanco.single.nomeBanco, 'Nubank');
      expect(s.atualizadoEm, DateTime(2026, 10, 3));
    });

    test('null sem banco que tenha informado saldo', () {
      expect(saldoNasContas(const []), isNull);
      expect(
        saldoNasContas([_conta('Cartão', fatura: 1, sync: DateTime(2026))]),
        isNull,
      );
    });
  });

  group('textoAtualizacaoSaldo', () {
    final agora = DateTime(2026, 10, 3, 15);

    test('hoje, ontem e data', () {
      expect(
        textoAtualizacaoSaldo(DateTime(2026, 10, 3, 9, 5), agora),
        'Atualizado hoje às 09:05',
      );
      expect(
        textoAtualizacaoSaldo(DateTime(2026, 10, 2, 23, 40), agora),
        'Atualizado ontem às 23:40',
      );
      expect(
        textoAtualizacaoSaldo(DateTime(2026, 9, 28, 8), agora),
        'Atualizado em 28/09 às 08:00',
      );
    });
  });
}
