import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/acesso/application/acesso_providers.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/domain/acesso_repository.dart';
import 'package:meubolso/features/acesso/presentation/admin_acessos_screen.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../support/fake_acesso_repository.dart';

void main() {
  final hoje = DateTime(2026, 10, 1, 15, 30);

  FakeAcessoRepository criarFake({bool comLista = true}) =>
      FakeAcessoRepository(
        agora: () => hoje,
        acessos: comLista
            ? [
                const Acesso(email: 'ana@cliente.com'),
                Acesso(
                  email: 'bia@cliente.com',
                  validoAte: DateTime(2026, 10, 4),
                  observacao: 'Pix setembro',
                ),
                Acesso(
                  email: 'caio@cliente.com',
                  validoAte: DateTime(2026, 9, 20),
                ),
              ]
            : const [],
      );

  Future<void> abrir(WidgetTester tester, FakeAcessoRepository fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          acessoRepositoryProvider.overrideWithValue(fake),
          acessoRelogioProvider.overrideWithValue(() => hoje),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AdminAcessosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirAcoes(WidgetTester tester, String email) async {
    await tester.tap(find.byTooltip('Ações de $email'));
    await tester.pumpAndSettle();
  }

  Finder campoEmail() => find.widgetWithText(TextFormField, 'E-mail');

  group('lista', () {
    testWidgets('mostra e-mails, chips de situação e a validade', (
      tester,
    ) async {
      await abrir(tester, criarFake());

      expect(find.text('ana@cliente.com'), findsOneWidget);
      expect(find.text('bia@cliente.com'), findsOneWidget);
      expect(find.text('caio@cliente.com'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Sem prazo'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Vence em 3 dias'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Vencido'), findsOneWidget);
      expect(find.textContaining('Válido até 04/10/2026'), findsOneWidget);
      expect(find.textContaining('Pix setembro'), findsOneWidget);
    });

    testWidgets('busca por parte do e-mail', (tester) async {
      await abrir(tester, criarFake());

      await tester.enterText(find.byType(TextField).first, 'bia');
      await tester.pumpAndSettle();

      expect(find.text('bia@cliente.com'), findsOneWidget);
      expect(find.text('ana@cliente.com'), findsNothing);
      expect(find.text('caio@cliente.com'), findsNothing);
    });

    testWidgets('busca sem resultado avisa', (tester) async {
      await abrir(tester, criarFake());

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum e-mail encontrado.'), findsOneWidget);
    });

    testWidgets('lista vazia avisa', (tester) async {
      await abrir(tester, criarFake(comLista: false));

      expect(find.text('Nenhum acesso cadastrado ainda.'), findsOneWidget);
    });

    test('filtrarAcessos ignora maiúsculas e devolve tudo sem termo', () {
      const lista = [
        Acesso(email: 'ana@cliente.com'),
        Acesso(email: 'bia@cliente.com'),
      ];
      expect(filtrarAcessos(lista, ''), lista);
      expect(filtrarAcessos(lista, 'BIA').map((a) => a.email), [
        'bia@cliente.com',
      ]);
    });
  });

  group('novo acesso', () {
    testWidgets('normaliza o e-mail e usa hoje + 30 dias', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await tester.tap(find.text('Novo acesso'));
      await tester.pumpAndSettle();
      await tester.enterText(campoEmail(), '  Novo@Cliente.COM ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final salvo = fake.acessos.firstWhere(
        (a) => a.email == 'novo@cliente.com',
      );
      expect(salvo.validoAte, DateTime(2026, 10, 31));
      expect(salvo.observacao, isNull);
      expect(find.text('novo@cliente.com'), findsOneWidget);
      expect(find.text('Acesso salvo.'), findsOneWidget);
    });

    testWidgets('e-mail inválido mostra mensagem e não salva', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await tester.tap(find.text('Novo acesso'));
      await tester.pumpAndSettle();
      await tester.enterText(campoEmail(), 'novo@cliente');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(fake.acessos.length, 3);
    });

    testWidgets('e-mail vazio pede o e-mail', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await tester.tap(find.text('Novo acesso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o e-mail.'), findsOneWidget);
      expect(fake.acessos.length, 3);
    });

    testWidgets('com "Sem prazo" ligado a validade fica nula', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await tester.tap(find.text('Novo acesso'));
      await tester.pumpAndSettle();
      await tester.enterText(campoEmail(), 'novo@cliente.com');
      await tester.tap(find.widgetWithText(SwitchListTile, 'Sem prazo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final salvo = fake.acessos.firstWhere(
        (a) => a.email == 'novo@cliente.com',
      );
      expect(salvo.validoAte, isNull);
    });
  });

  group('ações', () {
    testWidgets('renovar soma 30 dias à validade futura', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await abrirAcoes(tester, 'bia@cliente.com');
      await tester.tap(find.text('Renovar +30 dias'));
      await tester.pumpAndSettle();

      expect(
        fake.acessos.firstWhere((a) => a.email == 'bia@cliente.com').validoAte,
        DateTime(2026, 11, 3),
      );
      expect(find.text('Acesso renovado até 03/11/2026.'), findsOneWidget);
    });

    testWidgets('renovar conta vencida conta a partir de hoje', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await abrirAcoes(tester, 'caio@cliente.com');
      await tester.tap(find.text('Renovar +30 dias'));
      await tester.pumpAndSettle();

      expect(
        fake.acessos.firstWhere((a) => a.email == 'caio@cliente.com').validoAte,
        DateTime(2026, 10, 31),
      );
    });

    testWidgets('bloquear pede confirmação e vence ontem', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await abrirAcoes(tester, 'ana@cliente.com');
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();
      expect(find.text('Bloquear acesso?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
      await tester.pumpAndSettle();

      expect(
        fake.acessos.firstWhere((a) => a.email == 'ana@cliente.com').validoAte,
        DateTime(2026, 9, 30),
      );
      expect(find.widgetWithText(Chip, 'Vencido'), findsNWidgets(2));
      expect(find.text('Acesso bloqueado.'), findsOneWidget);
    });

    testWidgets('remover pede confirmação e tira da lista', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await abrirAcoes(tester, 'caio@cliente.com');
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(find.text('Remover acesso?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
      await tester.pumpAndSettle();

      expect(find.text('caio@cliente.com'), findsNothing);
      expect(fake.acessos.any((a) => a.email == 'caio@cliente.com'), isFalse);
      expect(find.text('Acesso removido.'), findsOneWidget);
    });

    testWidgets('cancelar a confirmação não altera nada', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);

      await abrirAcoes(tester, 'caio@cliente.com');
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('caio@cliente.com'), findsOneWidget);
      expect(fake.acessos.length, 3);
    });

    testWidgets('editar abre o diálogo com e-mail travado e observação', (
      tester,
    ) async {
      await abrir(tester, criarFake());

      await abrirAcoes(tester, 'bia@cliente.com');
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar acesso'), findsOneWidget);
      final email = tester.widget<TextField>(
        find.widgetWithText(TextField, 'E-mail'),
      );
      expect(email.readOnly, isTrue);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Pix setembro'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('falha do servidor aparece como mensagem', (tester) async {
      final fake = criarFake();
      await abrir(tester, fake);
      fake.erroOperacao = const AcessoException(
        'Não foi possível salvar agora. Verifique a conexão e tente '
        'novamente.',
      );

      await abrirAcoes(tester, 'bia@cliente.com');
      await tester.tap(find.text('Renovar +30 dias'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não foi possível salvar agora. Verifique a conexão e tente '
          'novamente.',
        ),
        findsOneWidget,
      );
    });
  });
}
