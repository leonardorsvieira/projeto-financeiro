import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meubolso/features/lancamentos/application/lembretes_controller.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/application/preferencias_service.dart';
import 'package:meubolso/features/lancamentos/presentation/lancamentos_list_screen.dart';

import '../../../support/fake_lancamentos_repository.dart';

class _FakeLembretesController extends LembretesController {
  PreferenciasLembretes? ultimasPreferencias;

  @override
  Future<void> build() async {}

  @override
  Future<void> alterarPreferencias(PreferenciasLembretes prefs) async {
    ultimasPreferencias = prefs;
  }
}

Widget _buildApp(
  _FakeLembretesController controller,
  FakeLancamentosRepository fakeRepo,
) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const LancamentosListScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      lancamentosRepositoryProvider.overrideWithValue(fakeRepo),
      lembretesControllerProvider.overrideWith(() => controller),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('diálogo abre com padrões e stepper ajusta dias antes',
      (tester) async {
    final controller = _FakeLembretesController();
    final fakeRepo = FakeLancamentosRepository();

    await tester.pumpWidget(_buildApp(controller, fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Lembretes de vencimento'), findsOneWidget);
    // Padrão 09:00, 3 dias antes.
    expect(find.text('3'), findsOneWidget);

    // Incrementa para 4 e salva.
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(controller.ultimasPreferencias, isNotNull);
    expect(controller.ultimasPreferencias!.diasAntes, 4);
    expect(controller.ultimasPreferencias!.hora, 9);

    // SnackBar confirma.
    expect(
      find.text('Lembretes: 4 dias antes às 09:00.'),
      findsOneWidget,
    );
  });

  testWidgets('dias antes = 0 mostra "apenas no dia"', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lembretes_hora': 9,
      'lembretes_minuto': 0,
      'lembretes_dias_antes': 0,
    });
    final controller = _FakeLembretesController();
    final fakeRepo = FakeLancamentosRepository();

    await tester.pumpWidget(_buildApp(controller, fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Apenas no dia do vencimento'), findsOneWidget);
    // Botão de diminuir desabilitado no mínimo.
    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
    );
    expect(minus.onPressed, isNull);
  });
}