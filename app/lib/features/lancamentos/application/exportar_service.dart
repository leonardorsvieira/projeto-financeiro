import 'package:intl/intl.dart';
import '../../relatorios/application/relatorios_providers.dart';
import '../domain/lancamento.dart';

class ExportarService {
  ExportarService._();

  static const _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  /// Gerar CSV de Lançamentos com BOM UTF-8 (\uFEFF) para abertura sem erros no Excel
  static String gerarCSV(List<Lancamento> lancamentos) {
    final formatData = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer();

    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Cabeçalho CSV (ponto-e-vírgula para compatibilidade com Excel em PT-BR)
    buffer.writeln(
      'ID;Data;Vencimento;Tipo;Descrição;Categoria;Forma de Pagamento;Valor (R\$)',
    );

    for (final l in lancamentos) {
      final dataStr = formatData.format(l.data);
      final vencStr =
          l.vencimento != null ? formatData.format(l.vencimento!) : '';
      final tipoStr = l.tipo == TipoLancamento.receita ? 'Receita' : 'Despesa';
      final valorReais =
          (l.valorCents / 100).toStringAsFixed(2).replaceAll('.', ',');

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

  /// Gerar CSV de Relatório Comparativo Mensal
  static String gerarCSVComparativo(DadosRelatorioComparativo dados) {
    final buffer = StringBuffer();

    // UTF-8 BOM para Excel
    buffer.write('\uFEFF');

    buffer.writeln(
      'Mês/Ano;Entradas (R\$);Saídas (R\$);Saldo do Mês (R\$);Patrimônio Acumulado (R\$)',
    );

    for (final p in dados.pontos) {
      final nomeMes = '${_meses[p.mesAno.month - 1]} ${p.mesAno.year}';
      final entradasStr = p.entradasReais.toStringAsFixed(2).replaceAll('.', ',');
      final saidasStr = p.saidasReais.toStringAsFixed(2).replaceAll('.', ',');
      final saldoStr = p.saldoMesReais.toStringAsFixed(2).replaceAll('.', ',');
      final patrimonioStr =
          p.patrimonioAcumuladoReais.toStringAsFixed(2).replaceAll('.', ',');

      final linha = [
        _escaparCampo(nomeMes),
        entradasStr,
        saidasStr,
        saldoStr,
        patrimonioStr,
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
