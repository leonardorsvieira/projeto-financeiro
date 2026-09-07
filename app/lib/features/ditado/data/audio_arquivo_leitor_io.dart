import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> lerArquivoAudio(String caminho) {
  return File(caminho).readAsBytes();
}