import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'glass.dart';

class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF0B7A4B);

  static const Color backgroundLight = Color(0xFFF7FAF8);
  static const Color backgroundDark = Color(0xFF111A16);

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static PageTransitionsTheme get _transicoes {
    const ios = GlassPageTransitionsBuilder(
      base: CupertinoPageTransitionsBuilder(),
    );
    const outros = GlassPageTransitionsBuilder(
      base: ZoomPageTransitionsBuilder(),
    );
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: outros,
        TargetPlatform.iOS: ios,
        TargetPlatform.macOS: ios,
        TargetPlatform.windows: outros,
        TargetPlatform.linux: outros,
        TargetPlatform.fuchsia: outros,
      },
    );
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;
    final fill = GlassTokens.fillDe(brightness);
    final fillForte = GlassTokens.fillDe(brightness, forte: true);
    final borda = GlassTokens.bordaDe(brightness);
    final sombra = Colors.black.withValues(alpha: isLight ? 0.06 : 0.20);
    const raio = GlassTokens.raio;
    const raioGrande = GlassTokens.raioGrande;
    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: _transicoes,
      appBarTheme: AppBarTheme(
        backgroundColor: fill,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        shape: Border(bottom: borda),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: borda.color,
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      cardTheme: CardThemeData(
        color: fill,
        elevation: 0,
        shadowColor: sombra,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(raio),
          side: borda,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fillForte,
        surfaceTintColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(raioGrande),
          side: borda,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: fillForte,
        modalBackgroundColor: fillForte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(raioGrande),
          ),
          side: borda,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: fillForte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borda,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: fill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: fill,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: borda,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
