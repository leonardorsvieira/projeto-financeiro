import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';
import 'package:meubolso/features/lancamentos/presentation/lancamentos_list_screen.dart';
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

  Future<(FakeLancamentosRepository, FakeDitadoRepository)> abrirConfirmacao(
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

  testWidgets('V1: FAB -> ditar -> rascunho em S8 -> salvar -> item na lista',
      (tester) async {
    final (fakeLancamentos, _) = await abrirConfirmacao(tester);

    expect(find.text('Confirmar lançamento'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(LancamentosListScreen), findsOneWidget);
    expect(fakeLancamentos.createCount, 1);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('R\$ 42,90'), findsOneWidget);
  });

  testWidgets('V2: correção por voz do campo descrição e salvar persistido',
      (tester) async {
    final fakeDitado = FakeDitadoRepository(
      rascunho: const RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
      ),
      correcao: 'Chipe',
    );
    final (fakeLancamentos, _) =
        await abrirConfirmacao(tester, ditado: fakeDitado);

    await tester.tap(find.byIcon(Icons.mic_none).at(0));
    await tester.pump();
    await tester.tap(find.byTooltip('Parar'));
    await tester.pumpAndSettle();

    expect(find.text('Chipe'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fakeLancamentos.createCount, 1);
    expect(fakeLancamentos.items.single.descricao, 'Chipe');
    expect(find.text('Chipe'), findsOneWidget);
  });

  testWidgets('V3: valor ausente bloqueia salvar até preencher', (tester) async {
    final (fakeLancamentos, _) = await abrirConfirmacao(
      tester,
      ditado: FakeDitadoRepository(
        rascunho: const RascunhoLancamento(
          descricao: 'Almoço',
          categoria: 'Alimentação',
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Informe um valor.'), findsOneWidget);
    expect(fakeLancamentos.createCount, 0);

    await tester.enterText(find.byType(TextFormField).at(1), '12,90');
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fakeLancamentos.createCount, 1);
    expect(fakeLancamentos.items.single.valorCents, 1290);
    expect(find.byType(LancamentosListScreen), findsOneWidget);
  });
}