import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';
import 'package:meubolso/features/ditado/presentation/lancamento_ditado_screen.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart'
    show TipoLancamento;
import 'package:meubolso/main.dart';

import '../../../support/fake_audio_recorder_service.dart';
import '../../../support/fake_ditado_providers.dart';
import '../../../support/fake_ditado_repository.dart';
import '../../../support/fake_wrappers.dart';

void main() {
  final audio = LancamentoAudio(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'audio/webm',
  );

  Future<(FakeLancamentosRepository, FakeDitadoRepository)> pumpConfirmacao(
    WidgetTester tester, {
    FakeDitadoRepository? ditado,
  }) async {
    final fakeAuth = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeLancamentos = FakeLancamentosRepository();
    final fakeAudio = FakeAudioRecorderService()..audio = audio;
    final fakeDitado = ditado ??
        FakeDitadoRepository(
          rascunho: const RascunhoLancamento(
            descricao: 'Almoço',
            valorTexto: '42,90',
            categoria: 'Alimentação',
            formaPagamento: 'Pix',
          ),
        );
    final relogio = FakeRelogio();

    await tester.pumpWidget(
      wrapWithDitadoFakes(
        fakeAuth: fakeAuth,
        fakeLancamentos: fakeLancamentos,
        fakeAudio: fakeAudio,
        fakeDitado: fakeDitado,
        relogio: relogio.call,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ditar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    relogio.avancar(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    return (fakeLancamentos, fakeDitado);
  }

  testWidgets('pré-preenche campos a partir do rascunho', (tester) async {
    await pumpConfirmacao(
      tester,
      ditado: FakeDitadoRepository(
        rascunho: const RascunhoLancamento(
          descricao: 'Almoço',
          valorTexto: '42,90',
          categoria: 'Alimentação',
          formaPagamento: 'Cartão de Crédito',
          dataIso: '2026-09-06',
          vencimentoIso: '2026-09-12',
        ),
      ),
    );

    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('42,90'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Cartão de Crédito'), findsOneWidget);
    expect(find.text('Data: 06/09/2026'), findsOneWidget);
    expect(find.text('Vencimento: 12/09/2026'), findsOneWidget);
  });

  testWidgets('correção por voz merge campo a campo preservando o resto',
      (tester) async {
    final ditado = FakeDitadoRepository(
      rascunho: const RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
      ),
      correcao: '30,00',
    );
    await pumpConfirmacao(tester, ditado: ditado);

    final micCampoValor = find.byIcon(Icons.mic_none).at(2);
    await tester.ensureVisible(micCampoValor);
    await tester.tap(micCampoValor);
    await tester.pump();

    await tester.tap(find.text('Toque para parar'));
    await tester.pumpAndSettle();

    expect(find.text('30,00'), findsOneWidget);
    expect(ditado.corrigirCount, 1);
    expect(ditado.ultimoCampo, CampoDitado.valor);
    expect(ditado.ultimoAudio, audio);
  });

  testWidgets('valor ausente deixa campo vazio com foco (D-36)', (tester) async {
    await pumpConfirmacao(
      tester,
      ditado: FakeDitadoRepository(
        rascunho: const RascunhoLancamento(
          descricao: 'Almoço',
          categoria: 'Alimentação',
        ),
      ),
    );

    final campoValor = find.byType(TextFormField).at(1);
    expect(tester.widget<TextFormField>(campoValor).controller!.text, isEmpty);
    final editavel = tester.widget<EditableText>(
      find.descendant(of: campoValor, matching: find.byType(EditableText)),
    );
    expect(editavel.focusNode.hasFocus, isTrue);
  });

  testWidgets('salvar cria lançamento no repositório (D-34)', (tester) async {
    final (fakeLancamentos, _) = await pumpConfirmacao(tester);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fakeLancamentos.createCount, 1);
    expect(fakeLancamentos.items.single.descricao, 'Almoço');
    expect(fakeLancamentos.items.single.valorCents, 4290);
    expect(fakeLancamentos.items.single.categoria, 'Alimentação');
    expect(fakeLancamentos.items.single.formaPagamento, 'Pix');
  });

  testWidgets('cancelar volta para a lista sem salvar', (tester) async {
    final (fakeLancamentos, _) = await pumpConfirmacao(tester);

    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(LancamentoDitadoScreen), findsOneWidget);
    expect(fakeLancamentos.createCount, 0);
  });

  testWidgets('_isSaving desabilita Salvar enquanto cria', (tester) async {
    final fakeLancamentos =
        FakeLancamentosRepository(null, const Duration(milliseconds: 300));
    final fakeAuth = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeDitado = FakeDitadoRepository(
      rascunho: const RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
      ),
    );
    final fakeAudio = FakeAudioRecorderService()..audio = audio;
    final relogio = FakeRelogio();

    await tester.pumpWidget(
      wrapWithDitadoFakes(
        fakeAuth: fakeAuth,
        fakeLancamentos: fakeLancamentos,
        fakeAudio: fakeAudio,
        fakeDitado: fakeDitado,
        relogio: relogio.call,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ditar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    relogio.avancar(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Salvando...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.pumpAndSettle();
    expect(fakeLancamentos.items.single.valorCents, 4290);
  });

  testWidgets('rascunho receita pré-preenche toggle e oculta vencimento',
      (tester) async {
    final (_, _) = await pumpConfirmacao(
      tester,
      ditado: FakeDitadoRepository(
        rascunho: const RascunhoLancamento(
          descricao: 'Salário',
          valorTexto: '3000,00',
          categoria: 'Outros',
          formaPagamento: 'Pix',
          tipo: 'receita',
        ),
      ),
    );

    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Vencimento (opcional)'), findsNothing);
    expect(find.textContaining('Vencimento:'), findsNothing);
  });

  testWidgets('trocar para Receita salva com tipo receita e sem vencimento',
      (tester) async {
    final (fakeLancamentos, _) = await pumpConfirmacao(tester);

    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fakeLancamentos.createCount, 1);
    final item = fakeLancamentos.items.single;
    expect(item.tipo, TipoLancamento.receita);
    expect(item.vencimento, isNull);
    expect(item.fixoMensal, isFalse);
  });

  testWidgets('correção por voz do tipo atualiza toggle', (tester) async {
    final ditado = FakeDitadoRepository(
      rascunho: const RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
      ),
      correcao: 'receita',
    );
    await pumpConfirmacao(tester, ditado: ditado);

    final micCampoTipo = find.byIcon(Icons.mic_none).at(0);
    await tester.tap(micCampoTipo);
    await tester.pump();

    await tester.tap(find.text('Toque para parar'));
    await tester.pumpAndSettle();

    expect(find.text('Receita'), findsOneWidget);
    expect(ditado.corrigirCount, 1);
    expect(ditado.ultimoCampo, CampoDitado.tipo);
    expect(ditado.ultimoTexto, isNull);
  });
}