import 'dart:typed_data';

import 'rascunho_lancamento.dart';

class LancamentoAudio {
  const LancamentoAudio({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class DitadoException implements Exception {
  const DitadoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

abstract class DitadoRepository {
  Future<RascunhoLancamento> reconhecer(LancamentoAudio audio);

  Future<String?> corrigirCampo(
    CampoDitado campo, {
    LancamentoAudio? audio,
    String? texto,
    RascunhoLancamento? rascunhoAtual,
  });

  Future<String> gerarAnaliseMensal(
    dynamic resumo,
    dynamic gastos,
    String mesAnoLabel,
  );
}