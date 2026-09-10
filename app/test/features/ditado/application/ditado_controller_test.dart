import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/ditado/application/ditado_providers.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

import '../../../support/fake_audio_recorder_service.dart';
import '../../../support/fake_ditado_repository.dart';

void main() {
  final audio = LancamentoAudio(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'audio/webm',
  );

  late ProviderContainer container;
  late FakeAudioRecorderService gravador;
  late FakeDitadoRepository repositorio;
  late DateTime agora;

  void passarTempo(int segundos) =>
      agora = agora.add(Duration(seconds: segundos));

  setUp(() {
    agora = DateTime(2026, 1, 1);
    gravador = FakeAudioRecorderService();
    repositorio = FakeDitadoRepository(
      rascunho: RascunhoLancamento(
        descricao: 'Almoço',
        valorTexto: '42,90',
        categoria: 'Alimentação',
      ),
    );
    container = ProviderContainer(
      overrides: [
        audioRecorderServiceProvider.overrideWithValue(gravador),
        ditadoRepositoryProvider.overrideWithValue(repositorio),
        ditadoRelogioProvider.overrideWithValue(() => agora),
      ],
    );
  });

  tearDown(() => container.dispose());

  DitadoState estado() => container.read(ditadoControllerProvider);

  test('fluxo completo: idle -> gravando -> processando -> sucesso', () async {
    gravador.audio = audio;
    final controller = container.read(ditadoControllerProvider.notifier);

    expect(estado(), isA<DitadoIdle>());

    await controller.gravar();
    expect(estado(), isA<DitadoGravando>());
    passarTempo(2);

    await controller.parar();
    expect(estado(), isA<DitadoSucesso>());
    final sucesso = estado() as DitadoSucesso;
    final rascunho = sucesso.lancamento;
    expect(rascunho, isNotNull);
    expect(rascunho!.descricao, 'Almoço');
    expect(rascunho.valorTexto, '42,90');

    expect(gravador.iniciarCount, 1);
    expect(gravador.pararCount, 1);
    expect(repositorio.reconhecerCount, 1);
    expect(repositorio.ultimoAudio, audio);
  });

  test('sem permissão de microfone vira erro', () async {
    gravador.permitido = false;
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();

    final erro = estado();
    expect(erro, isA<DitadoErro>());
    expect((erro as DitadoErro).mensagem, contains('microfone'));
    expect(gravador.iniciarCount, 0);
  });

  test('gravação nula volta a idle sem chamar a IA', () async {
    gravador.audio = null;
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();
    expect(estado(), isA<DitadoGravando>());

    await controller.parar();

    expect(estado(), isA<DitadoIdle>());
    expect(repositorio.reconhecerCount, 0);
  });

  test('erro de IA exibe a mensagem da exceção', () async {
    gravador.audio = audio;
    repositorio.erroLancado =
        const DitadoException('IA indisponível no momento (HTTP 500).');
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();
    passarTempo(2);
    await controller.parar();

    final erro = estado();
    expect(erro, isA<DitadoErro>());
    expect((erro as DitadoErro).mensagem, contains('indisponível'));
  });

  test('erro inesperado de reconhecimento vira mensagem genérica', () async {
    gravador.audio = audio;
    repositorio.erroLancado = StateError('boom');
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();
    passarTempo(2);
    await controller.parar();

    final erro = estado();
    expect(erro, isA<DitadoErro>());
    expect((erro as DitadoErro).mensagem, contains('entender'));
  });

  test('reiniciar volta para idle', () async {
    gravador.audio = audio;
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();
    passarTempo(2);
    await controller.parar();
    expect(estado(), isA<DitadoSucesso>());

    controller.reiniciar();
    expect(estado(), isA<DitadoIdle>());
  });

  test('gravação < 0,5s ignora e volta a idle sem chamar a IA', () async {
    gravador.audio = audio;
    final controller = container.read(ditadoControllerProvider.notifier);

    await controller.gravar();
    expect(estado(), isA<DitadoGravando>());

    await controller.parar();

    expect(estado(), isA<DitadoIdle>());
    expect(repositorio.reconhecerCount, 0);
  });
}