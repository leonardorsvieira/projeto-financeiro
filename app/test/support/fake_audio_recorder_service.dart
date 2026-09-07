import 'package:meubolso/features/ditado/data/audio_recorder_service.dart';
import 'package:meubolso/features/ditado/domain/ditado_repository.dart';

class FakeAudioRecorderService implements AudioRecorderService {
  bool permitido = true;
  LancamentoAudio? audio;
  Object? erroAoIniciar;
  Object? erroAoParar;

  int iniciarCount = 0;
  int pararCount = 0;

  @override
  Future<bool> temPermissao({bool request = true}) async => permitido;

  @override
  Future<void> iniciar() async {
    iniciarCount++;
    final erro = erroAoIniciar;
    if (erro != null) throw erro;
  }

  @override
  Future<LancamentoAudio?> parar() async {
    pararCount++;
    final erro = erroAoParar;
    if (erro != null) throw erro;
    return audio;
  }

  @override
  void dispose() {}
}