import 'perfil_investidor.dart';

/// Página que a Busca Google do Gemini consultou para escrever o guia.
class FonteConsultada {
  const FonteConsultada({required this.titulo, required this.url});

  final String titulo;
  final Uri url;
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
}

/// Gera o guia educativo de investimentos.
abstract class ConsultoriaRepository {
  /// [dadosCliente]: números agregados do cliente, em reais (ver
  /// `DadosConsultoria.paraPrompt`).
  Future<GuiaInvestimentos> gerar({
    required String dadosCliente,
    required PerfilInvestidor perfil,
  });
}
