import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePrefKey = 'app_theme_mode';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _carregarTema();
    return ThemeMode.system;
  }

  Future<void> _carregarTema() async {
    state = await lerTemaSalvo();
  }

  Future<void> definirTema(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_themePrefKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_themePrefKey, 'dark');
      } else {
        await prefs.remove(_themePrefKey);
      }
    } catch (_) {}
  }
}

/// Tema escolhido no app (`system` se nunca escolheu ou se a leitura falhar).
/// Também lido antes do app montar, para escolher a intro clara ou escura.
Future<ThemeMode> lerTemaSalvo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_themePrefKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  } catch (_) {
    return ThemeMode.system;
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
