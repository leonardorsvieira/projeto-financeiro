/// Bloco de conteúdo de uma seção de documento legal.
sealed class BlocoLegal {
  const BlocoLegal();
}

/// Parágrafo de texto corrido.
class ParagrafoLegal extends BlocoLegal {
  const ParagrafoLegal(this.texto);

  final String texto;
}

/// Lista com marcadores.
class ListaLegal extends BlocoLegal {
  const ListaLegal(this.itens);

  final List<String> itens;
}

class SecaoLegal {
  const SecaoLegal({required this.titulo, required this.blocos});

  final String titulo;
  final List<BlocoLegal> blocos;
}

/// Documento legal estruturado (Política de Privacidade, Termos de Uso).
class DocumentoLegal {
  const DocumentoLegal({
    required this.titulo,
    required this.versao,
    required this.introducao,
    required this.secoes,
  });

  final String titulo;

  /// Data ISO da versão (ex.: `2026-10-01`).
  final String versao;
  final String introducao;
  final List<SecaoLegal> secoes;

  /// Todo o texto do documento, unido por quebras de linha (usado em testes).
  String get textoCompleto {
    final partes = <String>[titulo, introducao];
    for (final secao in secoes) {
      partes.add(secao.titulo);
      for (final bloco in secao.blocos) {
        switch (bloco) {
          case ParagrafoLegal(:final texto):
            partes.add(texto);
          case ListaLegal(:final itens):
            partes.addAll(itens);
        }
      }
    }
    return partes.join('\n');
  }
}

/// '2026-10-01' vira '01/10/2026'.
String formatarVersao(String iso) {
  final partes = iso.split('-');
  if (partes.length != 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}
