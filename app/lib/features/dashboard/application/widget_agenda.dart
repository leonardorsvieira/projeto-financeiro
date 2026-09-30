import 'package:intl/intl.dart';

import '../../lancamentos/domain/lancamento.dart';

const int maxLinhasAgendaWidget = 3;

/// Uma linha "dd/MM | nome | 187,40" do widget da tela inicial.
class LinhaAgendaWidget {
  const LinhaAgendaWidget({
    required this.data,
    required this.nome,
    required this.valor,
  });

  final String data;
  final String nome;
  final String valor;

  @override
  bool operator ==(Object other) =>
      other is LinhaAgendaWidget &&
      other.data == data &&
      other.nome == nome &&
      other.valor == valor;

  @override
  int get hashCode => Object.hash(data, nome, valor);

  @override
  String toString() => 'LinhaAgendaWidget($data, $nome, $valor)';
}

/// Converte os próximos vencimentos (já ordenados) nas linhas do widget.
List<LinhaAgendaWidget> linhasAgendaWidget(
  List<Lancamento> proximos, {
  int max = maxLinhasAgendaWidget,
}) {
  final dia = DateFormat('dd/MM');
  final moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );
  final linhas = <LinhaAgendaWidget>[];
  for (final l in proximos) {
    final v = l.vencimento;
    if (v == null) continue;
    final nome = l.descricao.trim();
    linhas.add(
      LinhaAgendaWidget(
        data: dia.format(v),
        nome: nome.isEmpty ? 'Sem descrição' : nome,
        valor: moeda
            .format(l.valorCents / 100)
            .replaceAll(' ', ' ')
            .trim(),
      ),
    );
    if (linhas.length == max) break;
  }
  return linhas;
}
