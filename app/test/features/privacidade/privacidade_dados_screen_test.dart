import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/auth/application/aviso_login.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/auth/presentation/login_screen.dart';
import 'package:meubolso/features/dashboard/presentation/home_screen.dart';
import 'package:meubolso/features/home/domain/app_routes.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/privacidade/application/privacidade_providers.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/domain/exclusao_conta_repository.dart';
import 'package:meubolso/features/privacidade/presentation/documento_legal_screen.dart';
import 'package:meubolso/features/privacidade/presentation/privacidade_dados_screen.dart';
import 'package:meubolso/features/seguranca/application/limpeza_local.dart';
import 'package:meubolso/main.dart';

import '../../support/fake_auth.dart';
import '../../support/fake_exclusao_conta_repository.dart';
import '../../support/fake_lancamentos_repository.dart';

Lancamento _armario() {
  return Lancamento(
    id: 'armario',
    descricao: 'Armário',
    valorCents: 150000,
    categoria: 'Moradia',
    formaPagamento: 'Cartão de Crédito',
    data: DateTime(2026, 9, 5),
    createdAt: DateTime.utc(2026, 9, 5),
    updatedAt: DateTime.utc(2026, 9, 5),
  );
}

class _Cenario {
  final fakeAuth = FakeAuthRepository(
    const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
  );
  late final FakeLancamentosRepository fakeLancamentos;
  final fakeExclusao = FakeExclusaoContaRepository();

  int limpezas = 0;

  /// Quantas exclusões já tinham ido ao servidor quando os dados locais foram
  /// limpos (a limpeza só pode vir depois do sucesso no servidor).
  int exclusoesNaLimpeza = -1;

  final compartilhados = <({Uint8List bytes, String nome})>[];

  ProviderScope app() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        lancamentosRepositoryProvider.overrideWithValue(fakeLancamentos),
        exclusaoContaRepositoryProvider.overrideWithValue(fakeExclusao),
        limparDadosLocaisProvider.overrideWithValue(() async {
          limpezas++;
          exclusoesNaLimpeza = fakeExclusao.chamadas;
        }),
        compartilharArquivoProvider.overrideWithValue((bytes, nome) async {
          compartilhados.add((bytes: bytes, nome: nome));
        }),
      ],
      child: const MeuBolsoApp(),
    );
  }
}

void main() {
  tearDown(AvisoProximaSessao.consumir);

  /// Abre o app logado e navega até "Privacidade e dados".
  Future<_Cenario> abrirTela(
    WidgetTester tester, {
    List<Lancamento>? seed,
  }) async {
    final c = _Cenario()..fakeLancamentos = FakeLancamentosRepository(seed);
    await tester.pumpWidget(c.app());
    await tester.pumpAndSettle();
    GoRouter.of(
      tester.element(find.byType(HomeScreen)),
    ).push(AppRoutes.privacidadeEDados);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
  }

  Future<void> abrirDialogoDeExclusao(WidgetTester tester) async {
    await tocar(tester, find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
  }

  group('menu e itens da tela', () {
    testWidgets('menu da home leva a Privacidade e dados com os 5 itens',
        (tester) async {
      final c = _Cenario()..fakeLancamentos = FakeLancamentosRepository();
      await tester.pumpWidget(c.app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Opções'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Privacidade e dados'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacidadeDadosScreen), findsOneWidget);
      for (final item in [
        'Política de Privacidade',
        'Termos de Uso',
        'Exportar meus dados',
        'Falar com o responsável',
        'Excluir minha conta',
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      expect(find.text(emailPrivacidade), findsOneWidget);
    });

    testWidgets('Política de Privacidade abre o documento', (tester) async {
      await abrirTela(tester);

      await tocar(tester, find.text('Política de Privacidade'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentoLegalScreen), findsOneWidget);
    });
  });

  group('exportar meus dados', () {
    testWidgets('sem lançamentos avisa que não há o que exportar',
        (tester) async {
      final c = await abrirTela(tester);

      await tocar(tester, find.text('Exportar meus dados'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ainda não há lançamentos para exportar.'),
        findsOneWidget,
      );
      expect(c.compartilhados, isEmpty);
    });

    testWidgets('com lançamentos compartilha um CSV em UTF-8', (tester) async {
      final c = await abrirTela(tester, seed: [_armario()]);

      await tocar(tester, find.text('Exportar meus dados'));
      await tester.pumpAndSettle();

      expect(c.compartilhados, hasLength(1));
      final arquivo = c.compartilhados.single;
      expect(arquivo.nome, endsWith('.csv'));
      expect(utf8.decode(arquivo.bytes), contains('Armário'));
    });
  });

  group('excluir conta', () {
    testWidgets('o botão só habilita com EXCLUIR exato', (tester) async {
      await abrirTela(tester);
      await abrirDialogoDeExclusao(tester);

      final botao = find.widgetWithText(FilledButton, 'Excluir conta');
      bool habilitado() => tester.widget<FilledButton>(botao).onPressed != null;

      expect(find.text('Excluir sua conta?'), findsOneWidget);
      expect(habilitado(), isFalse);

      for (final texto in ['excluir', 'EXCLUI']) {
        await tester.enterText(find.byType(TextField), texto);
        await tester.pump();
        expect(habilitado(), isFalse, reason: texto);
      }

      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      expect(habilitado(), isTrue);
    });

    testWidgets('Cancelar fecha o diálogo sem excluir', (tester) async {
      final c = await abrirTela(tester);
      await abrirDialogoDeExclusao(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir sua conta?'), findsNothing);
      expect(c.fakeExclusao.chamadas, 0);
      expect(find.byType(PrivacidadeDadosScreen), findsOneWidget);
    });

    testWidgets(
        'sucesso: exclui no servidor, limpa o aparelho, sai e vai ao login',
        (tester) async {
      final c = await abrirTela(tester);
      await abrirDialogoDeExclusao(tester);

      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir conta'));
      await tester.pumpAndSettle();

      expect(c.fakeExclusao.chamadas, 1);
      expect(c.limpezas, 1);
      expect(c.exclusoesNaLimpeza, 1);
      expect(c.fakeAuth.signOutChamadas, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AvisoProximaSessao.consumir(), 'Conta excluída.');
    });

    testWidgets('erro: mostra a mensagem e mantém o usuário logado',
        (tester) async {
      final c = await abrirTela(tester);
      const mensagem =
          'Não foi possível excluir a conta agora. Verifique a conexão e '
          'tente novamente.';
      c.fakeExclusao.erro = const ExclusaoContaException(mensagem);
      await abrirDialogoDeExclusao(tester);

      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir conta'));
      await tester.pumpAndSettle();

      expect(find.text(mensagem), findsOneWidget);
      expect(c.fakeExclusao.chamadas, 1);
      expect(c.limpezas, 0);
      expect(c.fakeAuth.signOutChamadas, 0);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Excluir sua conta?'), findsOneWidget);
    });
  });

  testWidgets('login mostra o aviso único da sessão anterior', (tester) async {
    final fake = FakeAuthRepository(
      const AuthState(AuthStatus.unauthenticated),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fake),
          avisoLoginProvider.overrideWithValue(AvisoLogin('Conta excluída.')),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conta excluída.'), findsOneWidget);
  });
}
