import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../lancamentos/domain/lancamento.dart';
import 'relatorios_providers.dart';

class PdfReportService {
  PdfReportService._();

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

  /// Gera um relatório em PDF elegante e abre a interface nativa de impressão/compartilhamento.
  static Future<void> gerarECompartilharPDF({
    required DadosRelatorioComparativo dados,
    required List<Lancamento> lancamentos,
  }) async {
    final pdf = pw.Document();
    final fmtBrl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ');
    final fmtData = DateFormat('dd/MM/yyyy');
    final agoraStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Meu Bolso',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Relatório Financeiro Comparativo & Evolução',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Gerado em: $agoraStr',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 12),

            // Resumo Executivo (Cards)
            pw.Text(
              'Resumo do Período (${dados.pontos.length} meses)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildKpiCard(
                  rotulo: 'Total Receitas',
                  valor: fmtBrl.format(dados.totalEntradasCents / 100),
                  cor: PdfColors.green700,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  rotulo: 'Total Despesas',
                  valor: fmtBrl.format(dados.totalSaidasCents / 100),
                  cor: PdfColors.red700,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  rotulo: 'Saldo Líquido',
                  valor: fmtBrl.format(dados.saldoTotalCents / 100),
                  cor: dados.saldoTotalCents >= 0
                      ? PdfColors.green700
                      : PdfColors.red700,
                ),
                pw.SizedBox(width: 8),
                _buildKpiCard(
                  rotulo: 'Patrimônio Atual',
                  valor: fmtBrl.format(dados.patrimonioAtualCents / 100),
                  cor: PdfColors.blue800,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tabela Comparativa Mensal
            pw.Text(
              'Histórico Comparativo Mês a Mês',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: [
                'Mês / Ano',
                'Entradas (Receitas)',
                'Saídas (Despesas)',
                'Saldo do Mês',
                'Patrimônio Acumulado'
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              data: dados.pontos.map((p) {
                final nomeMes =
                    '${_meses[p.mesAno.month - 1]} / ${p.mesAno.year}';
                return [
                  nomeMes,
                  fmtBrl.format(p.entradasReais),
                  fmtBrl.format(p.saidasReais),
                  fmtBrl.format(p.saldoMesReais),
                  fmtBrl.format(p.patrimonioAcumuladoReais),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),

            // Tabela com últimos 30 lançamentos
            if (lancamentos.isNotEmpty) ...[
              pw.Text(
                'Detalhamento de Lançamentos Recentes',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: [
                  'Data',
                  'Tipo',
                  'Descrição',
                  'Categoria',
                  'Pagamento',
                  'Valor'
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                },
                data: lancamentos.take(40).map((l) {
                  final isReceita = l.tipo == TipoLancamento.receita;
                  final valorStr = fmtBrl.format(l.valorCents / 100);
                  return [
                    fmtData.format(l.data),
                    isReceita ? 'Receita' : 'Despesa',
                    l.descricao,
                    l.categoria,
                    l.formaPagamento,
                    isReceita ? '+ $valorStr' : '- $valorStr',
                  ];
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'MeuBolso_Relatorio_Financeiro.pdf',
    );
  }

  static pw.Widget _buildKpiCard({
    required String rotulo,
    required String valor,
    required PdfColor cor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
          color: PdfColors.grey100,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              rotulo,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
