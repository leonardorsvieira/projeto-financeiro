import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('lerTemaSalvo: sem escolha segue o sistema', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await lerTemaSalvo(), ThemeMode.system);
  });

  test('lerTemaSalvo: devolve o tema escolhido no app', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    expect(await lerTemaSalvo(), ThemeMode.dark);

    SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
    expect(await lerTemaSalvo(), ThemeMode.light);
  });
}
