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
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {
      state = ThemeMode.system;
    }
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

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
