import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meubolso/features/consultoria/application/consultoria_providers.dart';
import 'package:meubolso/features/consultoria/domain/guia_investimentos.dart';
import 'package:meubolso/features/consultoria/presentation/guia_investimentos_screen.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../../support/fake_consultoria_repository.dart';
import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_lancamentos_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeConsultoriaRepository consultoria, {
  List<Lancamento> lancamentos = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        consultoriaRepositoryProvider.overrideWithValue(consultoria),
        consultoriaRelogioProvider.overrideWithValue(
          () => DateTime(2026, 10, 3),
        ),
        lancamentosRepositoryProvider.overrideWithValue(
          FakeLancamentosRepository(lancamentos),
        ),
        investimentosRepositoryProvider.overrideWithValue(
          FakeInvestimentosRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const GuiaInvestimentosScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ButtonStyleButton _botao(WidgetTester tester, String texto) =>
    tester.widget<ButtonStyleButton>(find.ancestor(
      of: find.text(texto),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    ));

Future<void> _escolherPerfil(WidgetTester tester) async {
  await tester.tap(find.text('Aposentadoria / independência financeira'));
  await tester.tap(find.text('Mais de 5 anos'));
  await tester.tap(find.text('Moderado'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('só gera com o perfil completo e mostra guia, fontes e buscas',
      (tester) async {
    final consultoria = FakeConsultoriaRepository(
      guia: GuiaInvestimentos(
        texto: '## Sua situação hoje\nVocê guarda **R\$ 1.500,00** por mês.',
        geradoEm: DateTime(2026, 10, 3, 14, 30),
        fontes: [
          FonteConsultada(
            titulo: 'bcb.gov.br',
            url: Uri.parse('https://bcb.gov.br'),
          ),
        ],
        buscas: const ['taxa selic hoje'],
      ),
    );
    await _pump(
      tester,
      consultoria,
      lancamentos: [
        Lancamento(
          id: 'a',
          descricao: 'Pix para Fulano',
          categoria: 'Lazer',
          valorCents: 10000,
          formaPagamento: 'Pix',
          data: DateTime(2026, 9, 10),
          createdAt: DateTime(2026, 9, 10),
          updatedAt: DateTime(2026, 9, 10),
        ),
      ],
    );

    expect(_botao(tester, 'Gerar meu guia').onPressed, isNull);
    expect(find.textContaining('Escolha objetivo, prazo e risco'), findsOneWidget);

    await _escolherPerfil(tester);
    expect(_botao(tester, 'Gerar meu guia').onPressed, isNotNull);

    await tester.tap(find.text('Gerar meu guia'));
    await tester.pumpAndSettle();

    expect(consultoria.chamadas, 1);
    expect(consultoria.ultimoPerfil!.completo, isTrue);
    expect(consultoria.ultimosDados, contains('Lazer: R\$ 100,00'));
    expect(consultoria.ultimosDados, isNot(contains('Fulano')));

    expect(find.text('Sua situação hoje'), findsOneWidget);
    expect(find.textContaining('Você guarda'), findsOneWidget);
    expect(find.text('Gerado em 03/10/2026 às 14:30'), findsOneWidget);
    expect(find.text('Fontes consultadas'), findsOneWidget);
    expect(find.text('bcb.gov.br'), findsOneWidget);
    expect(find.text('taxa selic hoje'), findsOneWidget);
    expect(find.text('Gerar de novo'), findsOneWidget);
    expect(find.textContaining('Não é recomendação de investimento'),
        findsOneWidget);
  });

  testWidgets('erro da IA aparece na tela', (tester) async {
    await _pump(
      tester,
      FakeConsultoriaRepository(
        erroLancado: const DitadoException(
          'Você já gerou o máximo de guias de investimento de hoje. '
          'Tente amanhã.',
        ),
      ),
    );
    await _escolherPerfil(tester);
    await tester.tap(find.text('Gerar meu guia'));
    await tester.pumpAndSettle();

    expect(find.textContaining('máximo de guias'), findsOneWidget);
  });

  testWidgets('mostra os dados que vão para a IA', (tester) async {
    await _pump(tester, FakeConsultoriaRepository());
    await tester.tap(find.text('Dados que a IA vai usar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nenhum lançamento registrado'), findsOneWidget);
    expect(find.textContaining('descrições de lançamentos não são enviadas'),
        findsOneWidget);
  });
}
