import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/intro/presentation/intro_abertura.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Plataforma de vídeo falsa: o teste decide quando o vídeo carrega, acaba ou
/// falha.
class _PlataformaFalsa extends VideoPlayerPlatform {
  final eventos = StreamController<VideoEvent>();
  bool falharAoCriar = false;
  String? assetCriado;
  bool tocou = false;
  bool pausou = false;

  void carregar() => eventos.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 6),
      size: const Size(1080, 1080),
    ),
  );

  void acabar() => eventos.add(VideoEvent(eventType: VideoEventType.completed));

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (falharAoCriar) {
      throw PlatformException(code: 'erro', message: 'sem decodificador');
    }
    assetCriado = options.dataSource.asset;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => eventos.stream;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> play(int playerId) async => tocou = true;

  @override
  Future<void> pause(int playerId) async => pausou = true;

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(key: ValueKey('video'));

  @override
  Future<void> dispose(int playerId) async {}
}

void main() {
  late _PlataformaFalsa plataforma;
  late int terminou;

  setUp(() {
    plataforma = _PlataformaFalsa();
    VideoPlayerPlatform.instance = plataforma;
    terminou = 0;
  });

  Future<void> abrirIntro(WidgetTester tester, {bool escuro = false}) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: IntroAbertura(escuro: escuro, aoTerminar: () => terminou++),
      ),
    );
    await tester.pump();
  }

  Color? fundoDaIntro(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find.descendant(
          of: find.byKey(const ValueKey('intro-abertura')),
          matching: find.byType(ColoredBox),
        ),
      )
      .color;

  group('introEscura', () {
    test('segue o tema escolhido no app', () {
      expect(introEscura(ThemeMode.dark, Brightness.light), isTrue);
      expect(introEscura(ThemeMode.light, Brightness.dark), isFalse);
    });

    test('em "Sistema", segue o tema do aparelho', () {
      expect(introEscura(ThemeMode.system, Brightness.dark), isTrue);
      expect(introEscura(ThemeMode.system, Brightness.light), isFalse);
    });
  });

  // Desmonta a intro: cancela os timers do vídeo e o tempo máximo.
  Future<void> fechar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('toca o vídeo da intro e termina quando ele acaba', (
    tester,
  ) async {
    await abrirIntro(tester);
    expect(plataforma.assetCriado, videoIntroAsset);
    expect(fundoDaIntro(tester), corFundoIntro);
    expect(find.byKey(const ValueKey('video')), findsNothing);

    plataforma.carregar();
    await tester.pump();
    await tester.pump();
    expect(plataforma.tocou, isTrue);
    expect(find.byKey(const ValueKey('video')), findsOneWidget);
    expect(terminou, 0);

    plataforma.acabar();
    await tester.pump();
    expect(terminou, 1);

    await fechar(tester);
  });

  testWidgets('tema escuro toca o vídeo escuro, com o fundo escuro', (
    tester,
  ) async {
    await abrirIntro(tester, escuro: true);
    expect(plataforma.assetCriado, videoIntroEscuroAsset);
    expect(fundoDaIntro(tester), corFundoIntroEscuro);

    await fechar(tester);
  });

  testWidgets('toque na tela pula a intro (uma vez só)', (tester) async {
    await abrirIntro(tester);
    plataforma.carregar();
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('intro-abertura')));
    await tester.pump();
    expect(terminou, 1);
    expect(plataforma.pausou, isTrue);

    await tester.tap(find.byKey(const ValueKey('intro-abertura')));
    plataforma.acabar();
    await tester.pump();
    expect(terminou, 1);

    await fechar(tester);
  });

  testWidgets('vídeo que não carrega não prende o app', (tester) async {
    plataforma.falharAoCriar = true;
    await abrirIntro(tester);
    expect(terminou, 1);

    await fechar(tester);
  });

  testWidgets('vídeo travado: o app abre no tempo máximo', (tester) async {
    await abrirIntro(tester);
    await tester.pump(const Duration(seconds: 9));
    expect(terminou, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(terminou, 1);

    await fechar(tester);
  });
}
