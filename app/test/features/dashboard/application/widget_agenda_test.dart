import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meubolso/features/dashboard/application/widget_agenda.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';

Lancamento _l(String desc, int cents, DateTime? venc) {
  final agora = DateTime(2026, 9, 30);
  return Lancamento(
    id: desc,
    descricao: desc,
    categoria: 'Outros',
    valorCents: cents,
    formaPagamento: 'Pix',
    data: agora,
    vencimento: venc,
    createdAt: agora,
    updatedAt: agora,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('lista vazia', () {
    expect(linhasAgendaWidget([]), isEmpty);
  });

  test('formata data e valor', () {
    final r = linhasAgendaWidget([
      _l('Conta de luz', 18740, DateTime(2026, 10, 1)),
    ]);
    expect(
      r.single,
      const LinhaAgendaWidget(
        data: '01/10',
        nome: 'Conta de luz',
        valor: '187,40',
      ),
    );
  });

  test('separador de milhar', () {
    final r = linhasAgendaWidget([_l('Fatura', 128490, DateTime(2026, 10, 5))]);
    expect(r.single.valor, '1.284,90');
  });

  test('limita a 3 na ordem recebida', () {
    final lista = [
      for (var i = 1; i <= 5; i++) _l('c$i', 100, DateTime(2026, 10, i)),
    ];
    expect(linhasAgendaWidget(lista).map((e) => e.nome), ['c1', 'c2', 'c3']);
  });

  test('ignora vencimento nulo', () {
    final r = linhasAgendaWidget([
      _l('sem', 100, null),
      _l('com', 100, DateTime(2026, 10, 2)),
    ]);
    expect(r.map((e) => e.nome), ['com']);
  });

  test('descricao vazia vira Sem descrição', () {
    final r = linhasAgendaWidget([_l('   ', 100, DateTime(2026, 10, 2))]);
    expect(r.single.nome, 'Sem descrição');
  });
}
