import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meubolso/features/consultoria/application/consultoria_providers.dart';
import 'package:meubolso/features/consultoria/domain/guia_investimentos.dart';
import 'package:meubolso/features/consultoria/domain/indicadores_mercado.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';
import 'package:meubolso/features/consultoria/presentation/guia_investimentos_screen.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../../support/fake_consultoria_repository.dart';
import '../../../support/fake_guias_repository.dart';
import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_lancamentos_repository.dart';

const _perfilSalvo = PerfilInvestidor(
  objetivo: ObjetivoInvestimento.aposentadoria,
  prazo: PrazoInvestimento.longo,
  risco: ToleranciaRisco.moderado,
);

final _guiaAntigo = GuiaInvestimentos(
  texto: '## Sua situação hoje\nRelatório antigo.',
  geradoEm: DateTime(2026, 9, 1, 10),
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeConsultoriaRepository consultoria,
  required FakeGuiasRepository guias,
  List<Lancamento> lancamentos = const [],
  IndicadoresMercado? indicadores,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        consultoriaRepositoryProvider.overrideWithValue(consultoria),
        guiasRepositoryProvider.overrideWithValue(guias),
        indicadoresRepositoryProvider.overrideWithValue(
          FakeIndicadoresRepository(indicadores),
        ),
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

Future<void> _responderPerfil(WidgetTester tester) async {
  await tester.tap(find.text('Aposentadoria / independência financeira'));
  await tester.tap(find.text('Mais de 5 anos'));
  await tester.tap(find.text('Moderado'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('primeira vez: pergunta o perfil, salva e gera o relatório',
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
    final guias = FakeGuiasRepository();
    await _pump(
      tester,
      consultoria: consultoria,
      guias: guias,
      indicadores: IndicadoresMercado(
        consultadoEm: DateTime(2026, 10, 3, 15),
        selicMeta: 13.75,
        selicReuniao: DateTime(2026, 9, 16),
      ),
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

    expect(find.text('Qual é o seu principal objetivo?'), findsOneWidget);
    expect(_botao(tester, 'Gerar meu relatório').onPressed, isNull);
    expect(find.textContaining('feitas só uma vez'), findsOneWidget);

    await _responderPerfil(tester);
    await tester.tap(find.text('Gerar meu relatório'));
    await tester.pumpAndSettle();

    // Perfil e relatório guardados na conta.
    expect(guias.perfil?.risco, ToleranciaRisco.moderado);
    expect(guias.guia?.texto, contains('Você guarda'));
    expect(consultoria.chamadas, 1);
    expect(consultoria.ultimosDados, contains('Lazer: R\$ 100,00'));
    expect(consultoria.ultimosDados, isNot(contains('Fulano')));
    expect(consultoria.ultimosIndicadores, contains('Meta da taxa Selic: 13,75%'));

    // As perguntas somem; aparece o resumo do perfil e o relatório.
    expect(find.text('Qual é o seu principal objetivo?'), findsNothing);
    expect(find.text('Seu perfil'), findsOneWidget);
    expect(find.text('Alterar perfil'), findsOneWidget);
    expect(find.text('Sua situação hoje'), findsOneWidget);
    expect(find.text('Gerado em 03/10/2026 às 14:30'), findsOneWidget);
    expect(find.text('Banco Central — histórico da taxa Selic'), findsOneWidget);
    expect(find.text('bcb.gov.br'), findsOneWidget);
    expect(find.text('taxa selic hoje'), findsOneWidget);
    expect(find.text('Gerar novo relatório'), findsOneWidget);
    expect(find.textContaining('Não é recomendação de investimento'),
        findsOneWidget);
  });

  testWidgets('com perfil e relatório salvos: abre o relatório sem perguntar '
      'e "Gerar novo relatório" substitui', (tester) async {
    final consultoria = FakeConsultoriaRepository(
      guia: GuiaInvestimentos(
        texto: '## Sua situação hoje\nRelatório novo.',
        geradoEm: DateTime(2026, 10, 3, 16),
      ),
    );
    final guias = FakeGuiasRepository(perfil: _perfilSalvo, guia: _guiaAntigo);
    await _pump(tester, consultoria: consultoria, guias: guias);

    expect(find.text('Qual é o seu principal objetivo?'), findsNothing);
    expect(
      find.text('Aposentadoria / independência financeira · Mais de 5 anos · '
          'Moderado'),
      findsOneWidget,
    );
    expect(find.textContaining('Relatório antigo'), findsOneWidget);
    expect(consultoria.chamadas, 0);

    await tester.tap(find.text('Gerar novo relatório'));
    await tester.pumpAndSettle();

    expect(consultoria.chamadas, 1);
    expect(consultoria.ultimoPerfil?.objetivo, ObjetivoInvestimento.aposentadoria);
    expect(find.textContaining('Relatório novo'), findsOneWidget);
    expect(find.textContaining('Relatório antigo'), findsNothing);
    expect(guias.guia?.texto, contains('Relatório novo'));
    expect(guias.salvamentosDePerfil, 0);
  });

  testWidgets('"Alterar perfil" refaz as seleções e salva o perfil novo',
      (tester) async {
    final guias = FakeGuiasRepository(perfil: _perfilSalvo, guia: _guiaAntigo);
    await _pump(
      tester,
      consultoria: FakeConsultoriaRepository(),
      guias: guias,
    );

    await tester.tap(find.text('Alterar perfil'));
    await tester.pumpAndSettle();

    // Perguntas de volta, já com as respostas salvas marcadas.
    expect(find.text('Qual é o seu principal objetivo?'), findsOneWidget);
    final moderado = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Moderado'), matching: find.byType(ChoiceChip)),
    );
    expect(moderado.selected, isTrue);

    await tester.tap(find.text('Arrojado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    expect(guias.perfil?.risco, ToleranciaRisco.arrojado);
    expect(find.text('Qual é o seu principal objetivo?'), findsNothing);
    expect(find.textContaining('· Arrojado'), findsOneWidget);
    // O relatório antigo continua até gerar um novo.
    expect(find.textContaining('Relatório antigo'), findsOneWidget);
    expect(find.textContaining('Perfil atualizado'), findsOneWidget);
  });

  testWidgets('cancelar a alteração mantém o perfil salvo', (tester) async {
    final guias = FakeGuiasRepository(perfil: _perfilSalvo);
    await _pump(
      tester,
      consultoria: FakeConsultoriaRepository(),
      guias: guias,
    );

    await tester.tap(find.text('Alterar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conservador'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(guias.salvamentosDePerfil, 0);
    expect(find.textContaining('· Moderado'), findsOneWidget);
  });

  testWidgets('erro da IA aparece e o relatório anterior continua',
      (tester) async {
    await _pump(
      tester,
      consultoria: FakeConsultoriaRepository(
        erroLancado: const DitadoException(
          'Você já gerou o máximo de guias de investimento de hoje. '
          'Tente amanhã.',
        ),
      ),
      guias: FakeGuiasRepository(perfil: _perfilSalvo, guia: _guiaAntigo),
    );

    await tester.tap(find.text('Gerar novo relatório'));
    await tester.pumpAndSettle();

    expect(find.textContaining('máximo de guias'), findsOneWidget);
    expect(find.textContaining('Relatório antigo'), findsOneWidget);
  });

  testWidgets('mostra os dados que vão para a IA', (tester) async {
    await _pump(
      tester,
      consultoria: FakeConsultoriaRepository(),
      guias: FakeGuiasRepository(perfil: _perfilSalvo),
    );
    await tester.tap(find.text('Dados que a IA vai usar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nenhum lançamento registrado'), findsOneWidget);
    expect(find.textContaining('descrições de lançamentos não são enviadas'),
        findsOneWidget);
  });
}
