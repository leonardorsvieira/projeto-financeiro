import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'caderneta.dart';

/// Tema "Caderneta": livro-caixa de papel e tinta (claro) e caderneta
/// noturna (escuro). Opaco, sem sombras e sem blur.
class AppTheme {
  AppTheme._();

  static const Color backgroundLight = Color(0xFFF4ECD8);
  static const Color backgroundDark = Color(0xFF17213A);

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static PageTransitionsTheme get _transicoes {
    const ios = CadernetaPageTransitionsBuilder(
      base: CupertinoPageTransitionsBuilder(),
    );
    const outros = CadernetaPageTransitionsBuilder(
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

  static TextTheme _textTheme(CadernetaCores c) {
    TextStyle d(double s) => CadernetaTexto.display(size: s, cor: c.tinta);
    TextStyle b(double s, FontWeight w, {Color? cor}) =>
        CadernetaTexto.corpo(size: s, peso: w, cor: cor ?? c.tinta);
    return TextTheme(
      displayLarge: d(57),
      displayMedium: d(45),
      displaySmall: d(36),
      headlineLarge: d(32),
      headlineMedium: d(28),
      headlineSmall: d(24),
      titleLarge: d(22),
      titleMedium: b(16, FontWeight.w600),
      titleSmall: b(14, FontWeight.w600),
      bodyLarge: b(16, FontWeight.w400),
      bodyMedium: b(14, FontWeight.w400),
      bodySmall: b(12, FontWeight.w400, cor: c.apagado),
      labelLarge: b(14, FontWeight.w600),
      labelMedium: b(12, FontWeight.w500),
      labelSmall: b(11, FontWeight.w500),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final c = CadernetaCores.de(brightness);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.tinta,
      onPrimary: c.tintaSobrePrimaria,
      primaryContainer: c.papelChip,
      onPrimaryContainer: c.tinta,
      secondary: c.margem,
      onSecondary: c.papel,
      secondaryContainer: c.papelChip,
      onSecondaryContainer: c.tinta,
      tertiary: c.receita,
      onTertiary: c.papel,
      error: c.margem,
      onError: c.papel,
      surface: c.papel,
      onSurface: c.tinta,
      onSurfaceVariant: c.apagado,
      surfaceContainerLowest: c.papelClaro,
      surfaceContainerLow: c.papelClaro,
      surfaceContainer: c.papelClaro,
      surfaceContainerHigh: c.papelChip,
      surfaceContainerHighest: c.papelChip,
      outline: c.tinta,
      outlineVariant: c.divisor,
      inverseSurface: c.tinta,
      onInverseSurface: c.papel,
      inversePrimary: c.papel,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Colors.black,
    );
    final borda = BorderSide(color: c.tinta, width: Caderneta.borda);
    final raioCard = BorderRadius.circular(Caderneta.raioCard);
    final raioBotao = BorderRadius.circular(Caderneta.raioBotao);
    final formaCard = RoundedRectangleBorder(
      borderRadius: raioCard,
      side: borda,
    );
    final formaBotao = RoundedRectangleBorder(
      borderRadius: raioBotao,
      side: borda,
    );
    final textTheme = _textTheme(c);
    const semSombra = Colors.transparent;

    WidgetStateProperty<Color?> tinta = WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? c.divisor : c.tinta,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      splashFactory: InkRipple.splashFactory,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.papel,
      canvasColor: c.papel,
      hoverColor: c.hover,
      iconTheme: IconThemeData(color: c.tinta),
      pageTransitionsTheme: _transicoes,
      appBarTheme: AppBarTheme(
        backgroundColor: c.papel,
        surfaceTintColor: semSombra,
        shadowColor: semSombra,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.tinta,
        shape: Border(bottom: borda),
        titleTextStyle: CadernetaTexto.display(
          size: 22,
          cor: c.tinta,
          italico: true,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: c.divisor,
        indicatorColor: c.tinta,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: c.tinta,
        unselectedLabelColor: c.apagado,
        labelStyle: CadernetaTexto.corpo(size: 14, peso: FontWeight.w600),
        unselectedLabelStyle: CadernetaTexto.corpo(
          size: 14,
          peso: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.papelClaro,
        elevation: 0,
        shadowColor: semSombra,
        surfaceTintColor: semSombra,
        shape: formaCard,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.papelClaro,
        surfaceTintColor: semSombra,
        shadowColor: semSombra,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        shape: formaCard,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.papelClaro,
        modalBackgroundColor: c.papelClaro,
        surfaceTintColor: semSombra,
        shadowColor: semSombra,
        elevation: 0,
        modalBarrierColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Caderneta.raioCard),
          ),
          side: borda,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.papelClaro,
        surfaceTintColor: semSombra,
        shadowColor: semSombra,
        elevation: 0,
        shape: formaCard,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.papelClaro,
        surfaceTintColor: semSombra,
        shadowColor: semSombra,
        elevation: 0,
        indicatorColor: c.papelChip,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.papelClaro,
        elevation: 0,
        selectedItemColor: c.tinta,
        unselectedItemColor: c.apagado,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.tinta,
        foregroundColor: c.tintaSobrePrimaria,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: formaBotao,
        extendedTextStyle: CadernetaTexto.corpo(
          size: 14,
          peso: FontWeight.w600,
        ),
      ),
      listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.papelClaro,
        border: OutlineInputBorder(borderRadius: raioBotao, borderSide: borda),
        enabledBorder: OutlineInputBorder(
          borderRadius: raioBotao,
          borderSide: borda,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raioBotao,
          borderSide: BorderSide(color: c.tinta, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: raioBotao,
          borderSide: BorderSide(color: c.margem, width: Caderneta.borda),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: raioBotao,
          borderSide: BorderSide(color: c.margem, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.tinta,
          foregroundColor: c.tintaSobrePrimaria,
          elevation: 0,
          shadowColor: semSombra,
          surfaceTintColor: semSombra,
          minimumSize: const Size.fromHeight(48),
          shape: formaBotao,
          textStyle: CadernetaTexto.corpo(size: 16, peso: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.tinta,
          foregroundColor: c.tintaSobrePrimaria,
          elevation: 0,
          shadowColor: semSombra,
          surfaceTintColor: semSombra,
          minimumSize: const Size(64, 48),
          shape: formaBotao,
          textStyle: CadernetaTexto.corpo(size: 16, peso: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.tinta,
          side: borda,
          shape: RoundedRectangleBorder(borderRadius: raioBotao),
          textStyle: CadernetaTexto.corpo(size: 14, peso: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.tinta,
          shape: RoundedRectangleBorder(borderRadius: raioBotao),
          textStyle: CadernetaTexto.corpo(size: 14, peso: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.papelChip,
        selectedColor: c.tinta,
        disabledColor: c.papelChip,
        checkmarkColor: c.tintaSobrePrimaria,
        showCheckmark: false,
        side: borda,
        elevation: 0,
        pressElevation: 0,
        shadowColor: semSombra,
        surfaceTintColor: semSombra,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Caderneta.raioChip),
        ),
        labelStyle: CadernetaTexto.corpo(
          size: 13,
          peso: FontWeight.w500,
          cor: c.tinta,
        ),
        secondaryLabelStyle: CadernetaTexto.corpo(
          size: 13,
          peso: FontWeight.w500,
          cor: c.tintaSobrePrimaria,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divisor, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.tinta,
        linearTrackColor: c.trilho,
        linearMinHeight: Caderneta.alturaBarra,
        borderRadius: BorderRadius.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.papel : c.tinta,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.tinta : c.papelChip,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.tinta),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.tinta : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.tintaSobrePrimaria),
        side: borda,
      ),
      radioTheme: RadioThemeData(fillColor: tinta),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.tinta,
        contentTextStyle: CadernetaTexto.corpo(size: 14, cor: c.papel),
        actionTextColor: c.papelChip,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: raioBotao),
      ),
    );
  }
}
