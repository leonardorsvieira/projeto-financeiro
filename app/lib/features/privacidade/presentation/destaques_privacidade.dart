import 'package:flutter/material.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../domain/textos_legais.dart';

/// Quadro "Em destaque" com o essencial da privacidade (LGPD art. 33, VIII:
/// a transferência internacional do ditado precisa aparecer em destaque).
/// [compacto] mostra só a primeira frase (ditado e Google), sem título.
class DestaquesPrivacidade extends StatelessWidget {
  const DestaquesPrivacidade({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cores = CadernetaCores.of(context);
    final frases = compacto
        ? destaquesPrivacidade.take(1).toList()
        : destaquesPrivacidade;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.papelClaro,
        borderRadius: BorderRadius.circular(Caderneta.raioCard),
        border: Border.all(color: cores.contorno),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compacto) ...[
            Text('Em destaque', style: CadernetaTexto.display(size: 16)),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < frases.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: PhosphorIcon(
                    Icones.privacidade,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    frases[i],
                    style: CadernetaTexto.corpo(size: 13).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
