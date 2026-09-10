import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/ditado_repository.dart';
import 'audio_arquivo_leitor.dart';

abstract class AudioRecorderService {
  Future<bool> temPermissao();

  Future<void> iniciar();

  Future<LancamentoAudio?> parar();

  void dispose();
}

class RecordAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _gravador = AudioRecorder();

  @override
  Future<bool> temPermissao() async {
    return _gravador.hasPermission();
  }

  @override
  Future<void> iniciar() async {
    if (kIsWeb) {
      return _gravador.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          sampleRate: 16000,
        ),
        path: '',
      );
    } else {
      final diretorio = await getTemporaryDirectory();
      return _gravador.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 16000,
        ),
        path: '${diretorio.path}/ditado.wav',
      );
    }
  }

  @override
  Future<LancamentoAudio?> parar() async {
    final caminho = await _gravador.stop();
    if (caminho == null || caminho.isEmpty) return null;
    final Uint8List bytes;
    try {
      bytes = await lerArquivoAudio(caminho);
    } on Object {
      return null;
    }
    return LancamentoAudio(
      bytes: bytes,
      mimeType: kIsWeb ? 'audio/aac' : 'audio/wav',
    );
  }

  @override
  void dispose() => _gravador.dispose();
}