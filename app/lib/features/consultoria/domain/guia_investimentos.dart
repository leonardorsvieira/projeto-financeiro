import 'perfil_investidor.dart';

/// Página de onde vêm os dados do guia (indicadores oficiais ou Busca Google).
class FonteConsultada {
  const FonteConsultada({required this.titulo, required this.url});

  final String titulo;
  final Uri url;

  Map<String, dynamic> toJson() => {'titulo': titulo, 'url': url.toString()};

  /// Null se não for um link https válido (o app abre no navegador).
  static FonteConsultada? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = Uri.tryParse('${json['url'] ?? ''}');
    final titulo = json['titulo'];
    if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
    if (titulo is! String || titulo.trim().isEmpty) return null;
    return FonteConsultada(titulo: titulo, url: url);
  }
}

/// Guia de investimentos gerado pela IA: texto (Markdown simples), as fontes
/// da busca e as buscas que ela fez no Google.
class GuiaInvestimentos {
  const GuiaInvestimentos({
    required this.texto,
    required this.geradoEm,
    this.fontes = const [],
    this.buscas = const [],
  });

  final String texto;
  final DateTime geradoEm;
  final List<FonteConsultada> fontes;
  final List<String> buscas;

  /// O mesmo guia com [outras] fontes antes das da busca.
  GuiaInvestimentos comFontes(List<FonteConsultada> outras) =>
      GuiaInvestimentos(
        texto: texto,
        geradoEm: geradoEm,
        fontes: [...outras, ...fontes],
        buscas: buscas,
      );

  Map<String, dynamic> toJson() => {
        'texto': texto,
        'gerado_em': geradoEm.toUtc().toIso8601String(),
        'fontes': [for (final f in fontes) f.toJson()],
        'buscas': buscas,
      };

  /// Guia salvo na conta; null se o registro estiver incompleto.
  static GuiaInvestimentos? fromJson(Object? json) {
    if (json is! Map) return null;
    final texto = json['texto'];
    final geradoEm = DateTime.tryParse('${json['gerado_em'] ?? ''}');
    if (texto is! String || texto.trim().isEmpty || geradoEm == null) {
      return null;
    }
    final fontes = json['fontes'];
    final buscas = json['buscas'];
    return GuiaInvestimentos(
      texto: texto,
      geradoEm: geradoEm.toLocal(),
      fontes: [
        if (fontes is List)
          for (final f in fontes) ?FonteConsultada.fromJson(f),
      ],
      buscas: [if (buscas is List) ...buscas.whereType<String>()],
    );
  }
}

/// Perfil e último guia guardados na conta do usuário.
class GuiaSalvo {
  const GuiaSalvo({this.perfil, this.guia});

  /// Null enquanto o usuário não respondeu às perguntas.
  final PerfilInvestidor? perfil;
  final GuiaInvestimentos? guia;
}

/// Perfil de investidor e último guia, na conta (vale em todos os aparelhos).
abstract class GuiasRepository {
  Future<GuiaSalvo> carregar();

  Future<void> salvarPerfil(PerfilInvestidor perfil);

  Future<void> salvarGuia(GuiaInvestimentos guia);
}

/// Gera o guia educativo de investimentos.
abstract class ConsultoriaRepository {
  /// [dadosCliente]: números agregados do cliente, em reais (ver
  /// `DadosConsultoria.paraPrompt`). [indicadores]: indicadores de mercado
  /// do dia (`IndicadoresMercado.paraPrompt`), ou null se indisponíveis.
  Future<GuiaInvestimentos> gerar({
    required String dadosCliente,
    required PerfilInvestidor perfil,
    String? indicadores,
  });
}
