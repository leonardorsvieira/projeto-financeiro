import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> lerArquivoAudio(String url) async {
  final resposta = await http.get(Uri.parse(url));
  if (resposta.statusCode != 200) {
    throw StateError('Falha ao ler arquivo de áudio.');
  }
  return resposta.bodyBytes;
}