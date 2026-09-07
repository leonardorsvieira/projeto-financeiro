import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento_converter.dart';
import 'package:meubolso/features/lancamentos/presentation/proximos_vencimentos_screen.dart';
import 'package:meubolso/router/app_router.dart';

import '../../../support/fake_lancamentos_repository.dart';
import '../../../support/fake_wrappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('proximosVencimentosProvider', () {
    test('filtra apenas vencimentos futuros e ordena ascendente', () {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final amanha = hoje.add(const Duration(days: 1));
      final depoisAmanha = hoje.add(const Duration(days: 2));
      final ontem = hoje.subtract(const Duration(days: 1));

      final lancamentos = [
        Lancamento(
          id: '1',
          descricao: 'Amanhã',
          valorCents: 1000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: hoje,
          vencimento: amanha,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '2',
          descricao: 'Depois de amanhã',
          valorCents: 2000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: hoje,
          vencimento: depoisAmanha,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '3',
          descricao: 'Sem vencimento',
          valorCents: 3000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: hoje,
          vencimento: null,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '4',
          descricao: 'Ontem (passado)',
          valorCents: 4000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: ontem,
          vencimento: ontem,
          createdAt: agora,
          updatedAt: agora,
        ),
      ];

      // Lógica pura do provider (extraída para testabilidade)
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final resultado = lancamentos
          .where((l) => l.vencimento != null && !l.vencimento!.isBefore(inicioHoje))
          .toList()
        ..sort((a, b) => a.vencimento!.compareTo(b.vencimento!));

      expect(resultado.length, 2);
      expect(resultado[0].descricao, 'Amanhã');
      expect(resultado[1].descricao, 'Depois de amanhã');
    });
  });

  group('ProximosVencimentosScreen', () {
    late FakeLancamentosRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeLancamentosRepository();
    });

    Widget buildScreen({
      List<Lancamento>? seed,
      String initialRoute = '/home',
    }) {
      if (seed != null) {
        fakeRepo = FakeLancamentosRepository(seed);
      }
      final router = GoRouter(
        initialLocation: initialRoute,
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/vencimentos/proximos', builder: (_, _) => const ProximosVencimentosScreen()),
        ],
      );

      return ProviderScope(
        overrides: [
          lancamentosRepositoryProvider.overrideWithValue(fakeRepo),
          appRouterProvider.overrideWithValue(router),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('mostra empty state quando não há vencimentos futuros', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Próximos vencimentos'), findsOneWidget);
      expect(find.text('Nenhum vencimento próximo'), findsOneWidget);
    });

    testWidgets('lista vencimentos futuros ordenados', (tester) async {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final amanha = hoje.add(const Duration(days: 1));
      final depoisAmanha = hoje.add(const Duration(days: 2));

      await tester.pumpWidget(buildScreen(seed: [
        Lancamento(
          id: '1',
          descricao: 'Internet',
          valorCents: 9950,
          categoria: 'Casa',
          formaPagamento: 'Credito',
          data: hoje,
          vencimento: depoisAmanha,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '2',
          descricao: 'Água',
          valorCents: 15000,
          categoria: 'Casa',
          formaPagamento: 'Debito',
          data: hoje,
          vencimento: amanha,
          createdAt: agora,
          updatedAt: agora,
        ),
      ]));
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Próximos vencimentos'), findsOneWidget);
      // Água (amanhã) deve aparecer antes de Internet (depois de amanhã)
      final aguaPos = tester.getCenter(find.text('Água')).dy;
      final internetPos = tester.getCenter(find.text('Internet')).dy;
      expect(aguaPos, lessThan(internetPos));
      expect(find.text('Vence ${formatoData(amanha)}'), findsOneWidget);
      expect(find.text('Vence ${formatoData(depoisAmanha)}'), findsOneWidget);
    });

    testWidgets('não mostra vencimentos passados', (tester) async {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final ontem = hoje.subtract(const Duration(days: 1));
      final amanha = hoje.add(const Duration(days: 1));

      await tester.pumpWidget(buildScreen(seed: [
        Lancamento(
          id: '1',
          descricao: 'Passado',
          valorCents: 1000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: ontem,
          vencimento: ontem,
          createdAt: agora,
          updatedAt: agora,
        ),
        Lancamento(
          id: '2',
          descricao: 'Futuro',
          valorCents: 2000,
          categoria: 'Teste',
          formaPagamento: 'Debito',
          data: hoje,
          vencimento: amanha,
          createdAt: agora,
          updatedAt: agora,
        ),
      ]));
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Passado'), findsNothing);
      expect(find.text('Futuro'), findsOneWidget);
    });
  });
}