import 'package:flutter/material.dart';

/// Tokens da identidade "Caderneta" (livro-caixa de papel e tinta).
class CadernetaCores {
  const CadernetaCores._({
    required this.papel,
    required this.papelClaro,
    required this.papelChip,
    required this.trilho,
    required this.hover,
    required this.tinta,
    required this.tintaSobrePrimaria,
    required this.apagado,
    required this.margem,
    required this.receita,
    required this.pauta,
    required this.divisor,
  });

  final Color papel;
  final Color papelClaro;
  final Color papelChip;
  final Color trilho;
  final Color hover;
  final Color tinta;
  final Color tintaSobrePrimaria;
  final Color apagado;
  final Color margem;
  final Color receita;
  final Color pauta;
  final Color divisor;

  static const claro = CadernetaCores._(
    papel: Color(0xFFF4ECD8),
    papelClaro: Color(0xFFFBF6EA),
    papelChip: Color(0xFFEBE1C7),
    trilho: Color(0xFFE4D9BD),
    hover: Color(0xFFEFE5CC),
    tinta: Color(0xFF1D2A47),
    tintaSobrePrimaria: Color(0xFFF4ECD8),
    apagado: Color(0xFF6F6A5C),
    margem: Color(0xFFB3261E),
    receita: Color(0xFF2D6A3E),
    pauta: Color(0xFFD9CCAA),
    divisor: Color(0xFFCDBF9C),
  );

  // Noturna: superficie elevada #1c2844 (mais clara que o papel #17213a),
  // dando contraste suave para cards sobre o fundo.
  static const noturna = CadernetaCores._(
    papel: Color(0xFF17213A),
    papelClaro: Color(0xFF1C2844),
    papelChip: Color(0xFF243154),
    trilho: Color(0xFF2B3A61),
    hover: Color(0xFF202D4C),
    tinta: Color(0xFFF1E8D2),
    tintaSobrePrimaria: Color(0xFF17213A),
    apagado: Color(0xFFA9A18C),
    margem: Color(0xFFEF7A70),
    receita: Color(0xFF7FBF8E),
    pauta: Color(0xFF243154),
    divisor: Color(0xFF243154),
  );

  static CadernetaCores de(Brightness b) =>
      b == Brightness.light ? claro : noturna;

  static CadernetaCores of(BuildContext context) =>
      de(Theme.of(context).brightness);
}

class Caderneta {
  Caderneta._();

  static const double borda = 1.5;
  static const double raioCard = 4.0;
  static const double raioChip = 3.0;
  static const double raioBotao = 3.0;
  static const double alturaBarra = 8.0;
  static const double espacoPauta = 28.0;

  static const _paletaClara = <Color>[
    Color(0xFF1D2A47),
    Color(0xFFB3261E),
    Color(0xFF2D6A3E),
    Color(0xFF8A6D2F),
    Color(0xFF5C5C7A),
    Color(0xFF4A5A7A),
    Color(0xFFC8736B),
    Color(0xFF6F8F5A),
    Color(0xFF8B877C),
  ];

  /// Cores para categorias fora da lista padrão (ex.: vindas do Open
  /// Finance), para não repetirem a cor de "Outros".
  static const _extrasClara = <Color>[
    Color(0xFF2F6F73),
    Color(0xFF7A4A6B),
    Color(0xFFA4552A),
    Color(0xFF6B6B2E),
  ];

  static const _extrasEscura = <Color>[
    Color(0xFF7FC4C8),
    Color(0xFFC79BBE),
    Color(0xFFE39A6C),
    Color(0xFFC2C27A),
  ];

  static const _paletaEscura = <Color>[
    Color(0xFFF1E8D2),
    Color(0xFFEF7A70),
    Color(0xFF7FBF8E),
    Color(0xFFD1B46A),
    Color(0xFFA3A3C4),
    Color(0xFF8FA1C4),
    Color(0xFFE0A29B),
    Color(0xFFA3C48F),
    Color(0xFF8C8A80),
  ];

  static List<Color> paletaCategorias(Brightness b) =>
      b == Brightness.light ? _paletaClara : _paletaEscura;

  /// Cor estável para uma categoria desconhecida (mesmo nome, mesma cor).
  static Color corExtra(String categoria, Brightness b) {
    final extras = b == Brightness.light ? _extrasClara : _extrasEscura;
    final soma = categoria.codeUnits.fold<int>(0, (s, c) => s + c);
    return extras[soma % extras.length];
  }

  static Color corReceita(BuildContext c) => CadernetaCores.of(c).receita;

  static Color corReceitaFundo(BuildContext c) =>
      CadernetaCores.of(c).receita.withValues(alpha: 0.12);

  /// Ocre da paleta (avisos / destaques).
  static Color ocre(BuildContext c) =>
      paletaCategorias(Theme.of(c).brightness)[3];
}

class CadernetaTexto {
  CadernetaTexto._();

  static TextStyle display({
    double size = 22,
    Color? cor,
    bool italico = false,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    color: cor,
    fontWeight: FontWeight.w600,
    fontStyle: italico ? FontStyle.italic : FontStyle.normal,
    fontVariations: const [FontVariation.weight(600)],
    letterSpacing: -0.01 * size,
  );

  static TextStyle corpo({
    double size = 14,
    Color? cor,
    FontWeight peso = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    color: cor,
    fontWeight: peso,
    fontVariations: [FontVariation.weight(peso.value.toDouble())],
  );

  static TextStyle numero({
    double size = 14,
    Color? cor,
    FontWeight peso = FontWeight.w600,
  }) => TextStyle(
    fontFamily: 'IBMPlexMono',
    fontSize: size,
    color: cor,
    fontWeight: peso,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class _PautaPainter extends CustomPainter {
  _PautaPainter({required this.cor, required this.espacamento});

  final Color cor;
  final double espacamento;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 1;
    for (double y = espacamento; y < size.height; y += espacamento) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_PautaPainter old) =>
      old.cor != cor || old.espacamento != espacamento;
}

/// Margem dupla vermelha (equivale a "6px double").
class MargemVermelha extends StatelessWidget {
  const MargemVermelha({super.key, this.cor});

  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? CadernetaCores.of(context).margem;
    return SizedBox(
      width: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 1.5, color: c),
          Container(width: 1.5, color: c),
        ],
      ),
    );
  }
}

/// Papel pautado com borda de tinta e margem dupla vermelha à esquerda.
class PapelPautado extends StatelessWidget {
  const PapelPautado({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.espacamento = Caderneta.espacoPauta,
    this.margem = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double espacamento;
  final bool margem;

  @override
  Widget build(BuildContext context) {
    final c = CadernetaCores.of(context);
    final raio = BorderRadius.circular(Caderneta.raioCard);
    // Borda desenhada por cima, para a pauta não atravessar o contorno.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: raio,
        border: Border.all(color: c.tinta, width: Caderneta.borda),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.papelClaro, borderRadius: raio),
        child: ClipRRect(
          borderRadius: raio,
          child: CustomPaint(
            painter: _PautaPainter(cor: c.pauta, espacamento: espacamento),
            child: Stack(
              children: [
                Padding(padding: padding, child: child),
                if (margem)
                  const Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: MargemVermelha(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha o carimbo redondo "MB" (viewBox 100 do sketch): anel vermelho
/// girado -8 graus, anel tracejado e "MB" em Fraunces 800 na cor da tinta.
/// Usado pelo [CarimboLogo] e pelo gerador de icones (`tool/`).
void pintarCarimbo(
  Canvas canvas,
  double tamanho, {
  required Color cor,
  required Color tinta,
  Color? fundo,
  double escala = 1,
  bool recorteCircular = false,
}) {
  final u = tamanho / 100;
  canvas.save();
  if (recorteCircular) {
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, tamanho, tamanho)));
  }
  if (fundo != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, tamanho, tamanho),
      Paint()..color = fundo,
    );
  }
  canvas.translate(tamanho / 2, tamanho / 2);
  canvas.scale(escala);
  canvas.rotate(-8 * 3.141592653589793 / 180);
  canvas.translate(-tamanho / 2, -tamanho / 2);

  final centro = Offset(tamanho / 2, tamanho / 2);
  canvas.drawCircle(
    centro,
    33 * u,
    Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * u,
  );

  final tracejado = Paint()
    ..color = cor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4 * u;
  final oval = Path()
    ..addOval(Rect.fromCircle(center: centro, radius: 27 * u));
  for (final m in oval.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      canvas.drawPath(m.extractPath(d, d + 2.5 * u), tracejado);
      d += 5.5 * u;
    }
  }

  final tp = TextPainter(
    text: TextSpan(
      text: 'MB',
      style: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 30 * u,
        color: tinta,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(canvas, Offset(tamanho / 2 - tp.width / 2, 61 * u - base));
  canvas.restore();
}

class _CarimboPainter extends CustomPainter {
  _CarimboPainter({required this.cor, required this.tinta});

  final Color cor;
  final Color tinta;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarCarimbo(canvas, size.width, cor: cor, tinta: tinta);

  @override
  bool shouldRepaint(_CarimboPainter old) =>
      old.cor != cor || old.tinta != tinta;
}

/// Carimbo "MB" redondo (mesma marca do icone do app), sem sombra.
class CarimboLogo extends StatelessWidget {
  const CarimboLogo({super.key, this.tamanho = 36});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final c = CadernetaCores.of(context);
    return Semantics(
      label: 'Meu Bolso',
      child: CustomPaint(
        size: Size.square(tamanho),
        painter: _CarimboPainter(cor: c.margem, tinta: c.tinta),
      ),
    );
  }
}

/// Dá a cada rota fundo opaco para a página de baixo nunca aparecer.
class CadernetaPageTransitionsBuilder extends PageTransitionsBuilder {
  const CadernetaPageTransitionsBuilder({required this.base});

  final PageTransitionsBuilder base;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return base.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}
