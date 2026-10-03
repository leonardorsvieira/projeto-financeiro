import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Vídeos da intro: quadrados 1080×1080, ~6 s, carimbo "MB" desenhado em
/// tinta. O escuro é o claro com a paleta do tema escuro do app (papel azul,
/// tinta coral, letras creme). Na web os mesmos arquivos tocam no
/// `web/index.html` (`intro.js`), enquanto o Flutter carrega.
const videoIntroAsset = 'assets/intro/intro.mp4';
const videoIntroEscuroAsset = 'assets/intro/intro_escuro.mp4';

/// Cor do fundo de cada vídeo — a mesma do launch screen Android e do overlay
/// da web, para as bordas não aparecerem em telas que não são quadradas.
const corFundoIntro = Color(0xFFF1E8D7);
const corFundoIntroEscuro = Color(0xFF14203A);

/// A intro segue o tema do app: o que o cliente escolheu ou, se ficou em
/// "Sistema", o tema do aparelho.
bool introEscura(ThemeMode temaDoApp, Brightness temaDoAparelho) =>
    switch (temaDoApp) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => temaDoAparelho == Brightness.dark,
    };

/// Intro em vídeo mostrada ao abrir o app no celular. Chama [aoTerminar] uma
/// única vez: quando o vídeo acaba, quando o usuário toca na tela, quando o
/// vídeo falha ou, no máximo, depois de [tempoMaximo] (o app nunca fica preso
/// na intro). [escuro] é lido só na abertura.
class IntroAbertura extends StatefulWidget {
  const IntroAbertura({
    super.key,
    required this.aoTerminar,
    this.escuro = false,
    this.tempoMaximo = const Duration(seconds: 10),
  });

  final VoidCallback aoTerminar;
  final bool escuro;
  final Duration tempoMaximo;

  @override
  State<IntroAbertura> createState() => _IntroAberturaState();
}

class _IntroAberturaState extends State<IntroAbertura> {
  late final bool _escuro = widget.escuro;
  // mixWithOthers: o som da intro não interrompe a música de outro app.
  late final _controlador = VideoPlayerController.asset(
    _escuro ? videoIntroEscuroAsset : videoIntroAsset,
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
    final fundo = _escuro ? corFundoIntroEscuro : corFundoIntro;
    final barras = _escuro
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barras.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: fundo,
      ),
      child: GestureDetector(
        key: const ValueKey('intro-abertura'),
        behavior: HitTestBehavior.opaque,
        onTap: _terminar,
        child: ColoredBox(
          color: fundo,
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
