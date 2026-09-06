import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';
import 'package:meubolso/features/ditado/presentation/confirmacao_ditado_screen.dart';
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

  RascunhoLancamento rascunho() => const RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '40,00',
        categoria: 'Alimentação',
        formaPagamento: 'Pix',
      );

  Future<(FakeAudioRecorderService, FakeDitadoRepository, FakeRelogio)>
      pumpAteDitado(
    WidgetTester tester, {
    FakeDitadoRepository? ditado,
  }) async {
    final fakeAuth = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeLancamentos = FakeLancamentosRepository();
    final fakeAudio = FakeAudioRecorderService()..audio = audio;
    final fakeDitado = ditado ?? FakeDitadoRepository(rascunho: rascunho());
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
    expect(find.text('Ditar lançamento'), findsOneWidget);
    return (fakeAudio, fakeDitado, relogio);
  }

  testWidgets('idle -> gravando -> processando -> abre confirmação (S8)',
      (tester) async {
    final fakeDitado = FakeDitadoRepository(
      rascunho: rascunho(),
      delayReconhecer: const Duration(milliseconds: 200),
    );
    final (_, _, relogio) = await pumpAteDitado(tester, ditado: fakeDitado);

    expect(find.text('Toque para gravar'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    expect(find.text('Toque para parar'), findsOneWidget);
    relogio.avancar(const Duration(seconds: 2));

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Analisando…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(ConfirmacaoDitadoScreen), findsOneWidget);
    expect(fakeDitado.reconhecerCount, 1);
  });

  testWidgets('permissão negada mostra SnackBar e volta a gravar',
      (tester) async {
    final (fakeAudio, _, _) = await pumpAteDitado(tester);
    fakeAudio.permitido = false;

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();

    expect(
      find.text('Permita o acesso ao microfone para ditar.'),
      findsOneWidget,
    );
    expect(find.text('Toque para gravar'), findsOneWidget);
    expect(fakeAudio.iniciarCount, 0);
  });

  testWidgets('gravação curta (< 0,5 s) ignora e volta a gravar',
      (tester) async {
    final (_, fake, _) = await pumpAteDitado(tester);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(find.text('Toque para gravar'), findsOneWidget);
    expect(fake.reconhecerCount, 0);
  });

  testWidgets('erro da IA mostra mensagem e volta a gravar', (tester) async {
    final fakeDitado = FakeDitadoRepository(
      erroLancado:
          const DitadoException('IA indisponível no momento (HTTP 500).'),
    );
    final (_, _, relogio) = await pumpAteDitado(tester, ditado: fakeDitado);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    relogio.avancar(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(find.textContaining('indisponível'), findsOneWidget);
    expect(find.text('Toque para gravar'), findsOneWidget);
  });
}