import 'package:flutter/widgets.dart';

import 'icones.dart';

/// Ícone Phosphor Duotone: contorno de tinta + preenchimento suave na mesma
/// cor (a cor e o tamanho vêm do `IconTheme`, como em qualquer `Icon`).
///
/// Mesmo contrato do `PhosphorIcon` do pacote `phosphor_flutter`, que não
/// compila no Flutter atual (ver [Icones]). Estende `Icon` de propósito: o
/// contorno continua sendo o próprio widget e `find.byIcon(Icones.x)` o acha;
/// a camada de preenchimento é um `Icon` interno com o glifo secundário.
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    IconData super.icon, {
    super.key,
    super.size,
    super.color,
    super.semanticLabel,
    this.opacidadePreenchimento = 0.20,
  });

  /// Opacidade da camada de preenchimento (0.20 é o padrão do Phosphor).
  final double opacidadePreenchimento;

  @override
  Widget build(BuildContext context) {
    final contorno = super.build(context);
    final preenchimento = icon == null ? null : Icones.preenchimentoDe(icon!);
    if (preenchimento == null) return contorno;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: opacidadePreenchimento,
          child: Icon(preenchimento, size: size, color: color),
        ),
        contorno,
      ],
    );
  }
}
