import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Vídeo da intro: quadrado 1080×1080, ~6 s, carimbo "MB" desenhado em tinta.
/// Na web o mesmo arquivo toca no `web/index.html` (`intro.js`), enquanto o
/// Flutter carrega.
const videoIntroAsset = 'assets/intro/intro.mp4';

/// Creme do fundo do vídeo — o mesmo do launch screen Android e do overlay da
/// web, para as bordas não aparecerem em telas que não são quadradas.
const corFundoIntro = Color(0xFFF1E8D7);

/// Intro em vídeo mostrada ao abrir o app no celular. Chama [aoTerminar] uma
/// única vez: quando o vídeo acaba, quando o usuário toca na tela, quando o
/// vídeo falha ou, no máximo, depois de [tempoMaximo] (o app nunca fica preso
/// na intro).
class IntroAbertura extends StatefulWidget {
  const IntroAbertura({
    super.key,
    required this.aoTerminar,
    this.tempoMaximo = const Duration(seconds: 10),
  });

  final VoidCallback aoTerminar;
  final Duration tempoMaximo;

  @override
  State<IntroAbertura> createState() => _IntroAberturaState();
}

class _IntroAberturaState extends State<IntroAbertura> {
  // mixWithOthers: o som da intro não interrompe a música de outro app.
  final _controlador = VideoPlayerController.asset(
    videoIntroAsset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  Timer? _limite;
  bool _terminou = false;

  @override
  void initState() {
    super.initState();
    _limite = Timer(widget.tempoMaximo, _terminar);
    _controlador.addListener(_aoMudar);
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      await _controlador.initialize();
      if (!mounted || _terminou) return;
      setState(() {});
      await _controlador.play();
    } catch (e) {
      debugPrint('Intro: vídeo não carregou ($e)');
      _terminar();
    }
  }

  void _aoMudar() {
    final valor = _controlador.value;
    if (valor.hasError || valor.isCompleted) _terminar();
  }

  void _terminar() {
    if (_terminou) return;
    _terminou = true;
    _limite?.cancel();
    if (_controlador.value.isPlaying) _controlador.pause();
    if (mounted) widget.aoTerminar();
  }

  @override
  void dispose() {
    _limite?.cancel();
    _controlador.removeListener(_aoMudar);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valor = _controlador.value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: corFundoIntro,
      ),
      child: GestureDetector(
        key: const ValueKey('intro-abertura'),
        behavior: HitTestBehavior.opaque,
        onTap: _terminar,
        child: ColoredBox(
          color: corFundoIntro,
          child: Center(
            child: valor.isInitialized
                ? AspectRatio(
                    aspectRatio: valor.aspectRatio,
                    child: VideoPlayer(_controlador),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
