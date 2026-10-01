import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../home/domain/app_routes.dart';
import '../domain/documento_legal.dart';

/// Mostra um documento legal (Política de Privacidade, Termos de Uso).
/// Funciona logado ou não: quando abre sem nada para voltar (link direto na
/// web), o botão de voltar leva à home e o redirect decide o destino.
class DocumentoLegalScreen extends StatelessWidget {
  const DocumentoLegalScreen({super.key, required this.documento});

  final DocumentoLegal documento;

  @override
  Widget build(BuildContext context) {
    final cores = CadernetaCores.of(context);
    final semHistorico =
        !Navigator.of(context).canPop() && GoRouter.maybeOf(context) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(documento.titulo),
        leading: semHistorico
            ? IconButton(
                tooltip: 'Voltar',
                icon: const PhosphorIcon(Icones.voltar),
                onPressed: () => context.go(AppRoutes.home),
              )
            : null,
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    documento.titulo,
                    style: CadernetaTexto.display(size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versão de ${formatarVersao(documento.versao)}',
                    style: CadernetaTexto.corpo(size: 13, cor: cores.apagado),
                  ),
                  const SizedBox(height: 16),
                  _Paragrafo(documento.introducao),
                  for (final secao in documento.secoes) ...[
                    const SizedBox(height: 24),
                    Text(
                      secao.titulo,
                      style: CadernetaTexto.display(size: 19),
                    ),
                    const SizedBox(height: 8),
                    for (final bloco in secao.blocos) _Bloco(bloco),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco(this.bloco);

  final BlocoLegal bloco;

  @override
  Widget build(BuildContext context) {
    return switch (bloco) {
      ParagrafoLegal(:final texto) => _Paragrafo(texto),
      ListaLegal(:final itens) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 10),
                      child: Text('•', style: _estiloCorpo),
                    ),
                    Expanded(child: Text(item, style: _estiloCorpo)),
                  ],
                ),
              ),
          ],
        ),
      ),
    };
  }
}

class _Paragrafo extends StatelessWidget {
  const _Paragrafo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(texto, style: _estiloCorpo),
    );
  }
}

final TextStyle _estiloCorpo = CadernetaTexto.corpo(size: 15).copyWith(
  height: 1.5,
);
