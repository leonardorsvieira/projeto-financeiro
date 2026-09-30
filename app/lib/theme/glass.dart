import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Tokens do visual "glassmorphism" moderno (vidro fosco translúcido).
///
/// Os valores ficam aqui para que o `AppTheme` (sem `BuildContext`) e os
/// widgets usem exatamente as mesmas cores.
class GlassTokens {
  const GlassTokens._({
    required this.fill,
    required this.fillForte,
    required this.borda,
    required this.sombra,
  });

  final Color fill;
  final Color fillForte;
  final BorderSide borda;
  final BoxShadow sombra;

  static const double sigma = 20;
  static const double raio = 20;
  static const double raioGrande = 28;

  static const Color _fumaca = Color(0xFF0C1A16);

  static GlassTokens of(BuildContext context) =>
      GlassTokens.ofBrightness(Theme.of(context).brightness);

  static GlassTokens ofBrightness(Brightness b) => GlassTokens._(
    fill: fillDe(b),
    fillForte: fillDe(b, forte: true),
    borda: bordaDe(b),
    sombra: BoxShadow(
      color: Colors.black.withValues(
        alpha: b == Brightness.light ? 0.06 : 0.20,
      ),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  );

  static Color fillDe(Brightness b, {bool forte = false}) {
    if (b == Brightness.light) {
      return Colors.white.withValues(alpha: forte ? 0.78 : 0.55);
    }
    return _fumaca.withValues(alpha: forte ? 0.72 : 0.45);
  }

  static BorderSide bordaDe(Brightness b) => BorderSide(
    color: Colors.white.withValues(alpha: b == Brightness.light ? 0.45 : 0.16),
    width: 1,
  );
}

/// Fundo global: gradiente verde -> azul petróleo com manchas suaves de cor.
/// Totalmente opaco, então esconde o que estiver abaixo dele.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final cores = claro
        ? const [Color(0xFFDDF3E8), Color(0xFFCFEDEB), Color(0xFFCBDFEA)]
        : const [Color(0xFF06140F), Color(0xFF072020), Color(0xFF0A1B26)];
    final a = claro ? 0.40 : 0.30;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: cores,
                        ),
                      ),
                    ),
                    _mancha(c, -0.2, -0.1, 0.9, const Color(0xFF0B7A4B), a),
                    _mancha(c, 0.75, 0.1, 0.8, const Color(0xFF14B8A6), a),
                    _mancha(c, 0.0, 0.6, 1.0, const Color(0xFF0E5E7A), a),
                    _mancha(c, 0.9, 0.85, 0.7, const Color(0xFF34D399), a),
                  ],
                );
              },
            ),
          ),
        ),
        child,
      ],
    );
  }

  static Widget _mancha(
    BoxConstraints c,
    double fx,
    double fy,
    double fator,
    Color cor,
    double alpha,
  ) {
    final w = c.maxWidth.isFinite ? c.maxWidth : 400.0;
    final h = c.maxHeight.isFinite ? c.maxHeight : 800.0;
    final d = (w > h ? w : h) * 0.7 * fator;
    return Positioned(
      left: fx * w - d / 2,
      top: fy * h - d / 2,
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              cor.withValues(alpha: alpha),
              cor.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Superfície de vidro fosco. Use `blur: true` só em poucas superfícies
/// grandes (app bar, cards de destaque); nunca em itens repetidos de lista
/// (desempenho na web e em Android fraco).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blur = false,
    this.forte = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final bool forte;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final raio = borderRadius ?? BorderRadius.circular(GlassTokens.raio);
    final corpo = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: forte ? t.fillForte : t.fill,
        borderRadius: raio,
        border: Border.fromBorderSide(t.borda),
        boxShadow: [t.sombra],
      ),
      child: child,
    );
    if (!blur) return corpo;
    return ClipRRect(
      borderRadius: raio,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTokens.sigma,
          sigmaY: GlassTokens.sigma,
        ),
        child: corpo,
      ),
    );
  }
}

/// `Card` de vidro (mantém o tipo `Card` na árvore).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(GlassTokens.raio);
    return Card(
      margin: margin,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: raio),
      child: GlassSurface(blur: blur, borderRadius: raio, child: child),
    );
  }
}

/// Dá a cada rota o próprio fundo opaco (o Scaffold é transparente), para que
/// a página de baixo nunca apareça através da página aberta.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder({required this.base});

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
      GlassBackground(child: child),
    );
  }
}
