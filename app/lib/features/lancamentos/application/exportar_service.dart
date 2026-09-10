import 'package:intl/intl.dart';
import '../domain/lancamento.dart';

class ExportarService {
  ExportarService._();

  static String gerarCSV(List<Lancamento> lancamentos) {
    final formatData = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer();

    // Cabeçalho CSV (ponto-e-vírgula para compatibilidade com Excel em PT-BR)
    buffer.writeln('ID;Data;Vencimento;Tipo;Descrição;Categoria;Forma de Pagamento;Valor (R\$)');

    for (final l in lancamentos) {
      final dataStr = formatData.format(l.data);
      final vencStr = l.vencimento != null ? formatData.format(l.vencimento!) : '';
      final tipoStr = l.tipo == TipoLancamento.receita ? 'Receita' : 'Despesa';
      final valorReais = (l.valorCents / 100).toStringAsFixed(2).replaceAll('.', ',');

      final linha = [
        l.id,
        dataStr,
        vencStr,
        tipoStr,
        _escaparCampo(l.descricao),
        _escaparCampo(l.categoria),
        _escaparCampo(l.formaPagamento),
        valorReais,
      ].join(';');

      buffer.writeln(linha);
    }

    return buffer.toString();
  }

  static String _escaparCampo(String texto) {
    if (texto.contains(';') || texto.contains('"') || texto.contains('\n')) {
      return '"${texto.replaceAll('"', '""')}"';
    }
    return texto;
  }
}
