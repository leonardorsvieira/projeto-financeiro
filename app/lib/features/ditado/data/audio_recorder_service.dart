import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../domain/ditado_repository.dart';

abstract class AudioRecorderService {
  Future<bool> temPermissao();

  Future<void> iniciar();

  Future<LancamentoAudio?> parar();

  void dispose();
}

class RecordAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _gravador = AudioRecorder();

  @override
  Future<bool> temPermissao() => _gravador.hasPermission();

  @override
  Future<void> iniciar() {
    return _gravador.start(
      const RecordConfig(encoder: AudioEncoder.opus, numChannels: 1),
      path: 'ditado.webm',
    );
  }

  @override
  Future<LancamentoAudio?> parar() async {
    final url = await _gravador.stop();
    if (url == null || url.isEmpty) return null;
    final resposta = await http.get(Uri.parse(url));
    if (resposta.statusCode != 200) return null;
    return LancamentoAudio(
      bytes: resposta.bodyBytes,
      mimeType: 'audio/webm',
    );
  }

  @override
  void dispose() => _gravador.dispose();
}