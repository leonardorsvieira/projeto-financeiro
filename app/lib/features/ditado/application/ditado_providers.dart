import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio_recorder_service.dart';
import '../data/gemini_ditado_repository.dart';
import '../domain/ditado_repository.dart';
import '../domain/rascunho_lancamento.dart';

sealed class DitadoState {
  const DitadoState();
}

class DitadoIdle extends DitadoState {
  const DitadoIdle();
}

class DitadoGravando extends DitadoState {
  const DitadoGravando();
}

class DitadoProcessando extends DitadoState {
  const DitadoProcessando();
}

class DitadoSucesso extends DitadoState {
  const DitadoSucesso(this.rascunho);

  final RascunhoLancamento rascunho;
}

class DitadoErro extends DitadoState {
  const DitadoErro(this.mensagem);

  final String mensagem;
}

final ditadoRepositoryProvider =
    Provider<DitadoRepository>((ref) => GeminiDitadoRepository());

final audioRecorderServiceProvider =
    Provider<AudioRecorderService>((ref) => RecordAudioRecorderService());

final ditadoRelogioProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final ditadoControllerProvider =
    NotifierProvider<DitadoController, DitadoState>(DitadoController.new);

class DitadoController extends Notifier<DitadoState> {
  @override
  DitadoState build() => const DitadoIdle();

  AudioRecorderService get _gravador => ref.read(audioRecorderServiceProvider);

  DitadoRepository get _repositorio => ref.read(ditadoRepositoryProvider);

  DateTime Function() get _agora => ref.read(ditadoRelogioProvider);

  DateTime? _inicioGravacao;

  Future<void> gravar() async {
    if (state is DitadoGravando) return;
    try {
      final permitido = await _gravador.temPermissao();
      if (!permitido) {
        state = const DitadoErro('Permita o acesso ao microfone para ditar.');
        return;
      }
      await _gravador.iniciar();
      _inicioGravacao = _agora();
      state = const DitadoGravando();
    } on Object catch (e) {
      String mensagem;
      if (kIsWeb) {
        mensagem = 'Não consegui acessar o microfone. '
            'Verifique se o site usa HTTPS (localhost funciona) e '
            'se o navegador permitiu o microfone nas configurações.';
      } else {
        mensagem = 'Não consegui acessar o microfone. '
            'Verifique as permissões do app nas configurações do sistema.';
      }
      debugPrint('Erro ao iniciar gravação: $e');
      state = DitadoErro(mensagem);
    }
  }

  Future<void> parar() async {
    if (state is! DitadoGravando) return;
    final inicio = _inicioGravacao;
    _inicioGravacao = null;
    final audio = await _gravador.parar();
    if (audio == null) {
      state = const DitadoIdle();
      return;
    }
    final duracao =
        inicio == null ? Duration.zero : _agora().difference(inicio);
    if (duracao < const Duration(milliseconds: 500)) {
      state = const DitadoIdle();
      return;
    }
    state = const DitadoProcessando();
    try {
      final rascunho = await _repositorio.reconhecer(audio);
      state = DitadoSucesso(rascunho);
    } on DitadoException catch (e) {
      state = DitadoErro(e.mensagem);
    } on Object {
      state = const DitadoErro('Não consegui entender. Tente de novo.');
    }
  }

  void reiniciar() => state = const DitadoIdle();
}