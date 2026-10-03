import 'guia_investimentos.dart';

/// Expectativa do boletim Focus para o fim de um ano.
class ExpectativaAnual {
  const ExpectativaAnual({required this.ano, required this.mediana});

  final int ano;
  final double mediana;
}

/// Indicadores públicos de mercado (Banco Central e IBGE) que a Edge Function
/// `indicadores` busca na hora de gerar o guia. Qualquer um pode faltar (a
/// fonte não respondeu).
class IndicadoresMercado {
  const IndicadoresMercado({
    required this.consultadoEm,
    this.selicMeta,
    this.selicReuniao,
    this.selicAnterior,
    this.focusData,
    this.focusSelic = const [],
    this.focusIpca = const [],
    this.ipca12m,
    this.ipcaReferencia,
    this.dolar,
    this.dolarData,
  });

  final DateTime consultadoEm;

  /// Meta Selic vigente (% ao ano) e a reunião do Copom que a definiu.
  final double? selicMeta;
  final DateTime? selicReuniao;
  final double? selicAnterior;

  final DateTime? focusData;
  final List<ExpectativaAnual> focusSelic;
  final List<ExpectativaAnual> focusIpca;

  /// IPCA acumulado em 12 meses (%) e o mês de referência ("agosto 2026").
  final double? ipca12m;
  final String? ipcaReferencia;

  /// Dólar PTAX (venda) e a data da cotação.
  final double? dolar;
  final DateTime? dolarData;

  bool get vazio =>
      selicMeta == null &&
      focusSelic.isEmpty &&
      focusIpca.isEmpty &&
      ipca12m == null &&
      dolar == null;

  factory IndicadoresMercado.fromJson(Map<String, dynamic> json) {
    double? numero(Object? v) => v is num ? v.toDouble() : null;
    DateTime? data(Object? v) => v is String ? DateTime.tryParse(v) : null;
    Map<String, dynamic>? mapa(Object? v) =>
        v is Map<String, dynamic> ? v : null;
    List<ExpectativaAnual> expectativas(Object? v) => [
          if (v is List)
            for (final e in v.whereType<Map<String, dynamic>>())
              if (e['ano'] is num && e['mediana'] is num)
                ExpectativaAnual(
                  ano: (e['ano'] as num).toInt(),
                  mediana: (e['mediana'] as num).toDouble(),
                ),
        ];

    final selic = mapa(json['selic']);
    final focus = mapa(json['focus']);
    final ipca = mapa(json['ipca12m']);
    final dolar = mapa(json['dolar']);
    return IndicadoresMercado(
      consultadoEm: data(json['consultadoEm'])?.toLocal() ?? DateTime.now(),
      selicMeta: numero(selic?['meta']),
      selicReuniao: data(selic?['reuniao']),
      selicAnterior: numero(selic?['anterior']),
      focusData: data(focus?['data']),
      focusSelic: expectativas(focus?['selic']),
      focusIpca: expectativas(focus?['ipca']),
      ipca12m: numero(ipca?['valor']),
      ipcaReferencia: ipca?['referencia'] as String?,
      dolar: numero(dolar?['venda']),
      dolarData: data(dolar?['data']),
    );
  }

  static String _pct(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')}%';

  static String _data(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  /// Texto para o prompt do guia, com a data de cada número.
  String paraPrompt() {
    if (vazio) return 'Indisponíveis agora (as fontes não responderam).';
    final linhas = <String>[
      'Consultados em ${_data(consultadoEm)} (Banco Central e IBGE):',
    ];
    final meta = selicMeta;
    if (meta != null) {
      final reuniao = selicReuniao;
      final anterior = selicAnterior;
      linhas.add('- Meta da taxa Selic: ${_pct(meta)} ao ano'
          '${reuniao == null ? '' : ', definida pelo Copom em ${_data(reuniao)}'}'
          '${anterior == null || anterior == meta ? '' : ' (antes: ${_pct(anterior)})'}');
    }
    final ipca = ipca12m;
    if (ipca != null) {
      linhas.add('- IPCA acumulado em 12 meses: ${_pct(ipca)}'
          '${ipcaReferencia == null ? '' : ' (até $ipcaReferencia)'}');
    }
    if (focusSelic.isNotEmpty || focusIpca.isNotEmpty) {
      String lista(String nome, List<ExpectativaAnual> e) => e
          .map((x) => '$nome no fim de ${x.ano}: ${_pct(x.mediana)}')
          .join('; ');
      final partes = [
        if (focusSelic.isNotEmpty) lista('Selic', focusSelic),
        if (focusIpca.isNotEmpty) lista('IPCA', focusIpca),
      ];
      final data = focusData;
      linhas.add('- Expectativa do mercado (boletim Focus'
          '${data == null ? '' : ' de ${_data(data)}'}): ${partes.join('; ')}');
    }
    final usd = dolar;
    if (usd != null) {
      final data = dolarData;
      linhas.add('- Dólar (PTAX, venda): R\$ '
          '${usd.toStringAsFixed(2).replaceAll('.', ',')}'
          '${data == null ? '' : ' em ${_data(data)}'}');
    }
    return linhas.join('\n');
  }

  /// Páginas oficiais de onde vêm os números (mostradas como fontes do guia).
  List<FonteConsultada> get fontes => [
        if (selicMeta != null)
          FonteConsultada(
            titulo: 'Banco Central — histórico da taxa Selic',
            url: Uri.parse(
              'https://www.bcb.gov.br/controleinflacao/historicotaxasjuros',
            ),
          ),
        if (focusSelic.isNotEmpty || focusIpca.isNotEmpty)
          FonteConsultada(
            titulo: 'Banco Central — boletim Focus',
            url: Uri.parse('https://www.bcb.gov.br/publicacoes/focus'),
          ),
        if (ipca12m != null)
          FonteConsultada(
            titulo: 'IBGE — IPCA acumulado em 12 meses',
            url: Uri.parse('https://sidra.ibge.gov.br/tabela/1737'),
          ),
        if (dolar != null)
          FonteConsultada(
            titulo: 'Banco Central — cotação do dólar (PTAX)',
            url: Uri.parse(
              'https://www.bcb.gov.br/estabilidadefinanceira/historicocotacoes',
            ),
          ),
      ];
}

/// Busca os indicadores de mercado (null se não for possível agora — o guia
/// é gerado mesmo assim).
abstract class IndicadoresRepository {
  Future<IndicadoresMercado?> buscar();
}
