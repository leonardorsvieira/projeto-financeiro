import 'package:flutter/material.dart';

/// Texto gerado pela IA com o Markdown simples que ela costuma mandar:
/// títulos (`#`, `##`, `###`), listas (`-`, `*`, `•`, `1.`) e `**negrito**`.
/// O resto vira parágrafo comum (nada de HTML nem links).
class TextoIA extends StatelessWidget {
  const TextoIA(this.texto, {super.key});

  final String texto;

  static final _titulo = RegExp(r'^#{1,6}\s+');
  static final _marcador = RegExp(r'^[-*•]\s+');
  static final _numerado = RegExp(r'^(\d{1,2})[.)]\s+');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corpo = theme.textTheme.bodyMedium;
    final blocos = <Widget>[];

    for (final bruta in texto.split('\n')) {
      final linha = bruta.trim();
      if (linha.isEmpty) {
        if (blocos.isNotEmpty) blocos.add(const SizedBox(height: 8));
        continue;
      }
      if (_titulo.hasMatch(linha)) {
        blocos.add(Padding(
          padding: EdgeInsets.only(top: blocos.isEmpty ? 0 : 8, bottom: 4),
          child: Text.rich(
            _comNegrito(linha.replaceFirst(_titulo, ''), null),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ));
        continue;
      }
      final numero = _numerado.firstMatch(linha);
      if (_marcador.hasMatch(linha) || numero != null) {
        final rotulo = numero != null ? '${numero.group(1)}.' : '•';
        final conteudo = numero != null
            ? linha.substring(numero.end)
            : linha.replaceFirst(_marcador, '');
        blocos.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 22, child: Text(rotulo, style: corpo)),
              Expanded(child: Text.rich(_comNegrito(conteudo, corpo))),
            ],
          ),
        ));
        continue;
      }
      blocos.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text.rich(_comNegrito(linha, corpo)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocos,
    );
  }

  /// `**trecho**` em negrito; asteriscos soltos de itálico somem.
  static TextSpan _comNegrito(String linha, TextStyle? estilo) {
    final partes = linha.split('**');
    return TextSpan(
      style: estilo,
      children: [
        for (final (i, parte) in partes.indexed)
          if (parte.isNotEmpty)
            TextSpan(
              text: parte.replaceAll(RegExp(r'(?<!\w)\*|\*(?!\w)'), ''),
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
      ],
    );
  }
}
