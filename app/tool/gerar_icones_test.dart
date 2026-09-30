// Gerador dos icones do Meu Bolso (carimbo). Fica fora de test/ para o
// `flutter test` normal nao rodar. Uso, a partir de app/:
//   PowerShell: $env:GERAR_ICONES='1'; flutter test tool/gerar_icones_test.dart
//   bash:       GERAR_ICONES=1 flutter test tool/gerar_icones_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/theme/caderneta.dart';

const _creme = Color(0xFFF4ECD8);
const _vermelho = Color(0xFFB3261E);
const _tinta = Color(0xFF1D2A47);

Future<void> _gravar(
  String caminho,
  int px, {
  bool fundo = true,
  double escala = 1,
  bool circular = false,
}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  pintarCarimbo(
    canvas,
    px.toDouble(),
    cor: _vermelho,
    tinta: _tinta,
    fundo: fundo ? _creme : null,
    escala: escala,
    recorteCircular: circular,
  );
  final img = await rec.endRecording().toImage(px, px);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File(caminho);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets(
    'gera icones',
    (tester) async {
      final fonte = File('assets/fonts/Fraunces.ttf').readAsBytesSync();
      final loader = FontLoader('Fraunces')
        ..addFont(Future.value(ByteData.sublistView(fonte)));
      await loader.load();

      await tester.runAsync(() async {
        const res = 'android/app/src/main/res';
        const dens = {
          'mdpi': [48, 108],
          'hdpi': [72, 162],
          'xhdpi': [96, 216],
          'xxhdpi': [144, 324],
          'xxxhdpi': [192, 432],
        };
        for (final e in dens.entries) {
          final dir = '$res/mipmap-${e.key}';
          await _gravar('$dir/ic_launcher.png', e.value[0]);
          await _gravar('$dir/ic_launcher_round.png', e.value[0],
              circular: true);
          await _gravar('$dir/ic_launcher_foreground.png', e.value[1],
              fundo: false, escala: 0.62);
        }

        const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
        final json = jsonDecode(File('$ios/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
        for (final i in json['images'] as List) {
          final tam = double.parse((i['size'] as String).split('x').first);
          final esc = double.parse((i['scale'] as String).replaceAll('x', ''));
          await _gravar('$ios/${i['filename']}', (tam * esc).round());
        }

        await _gravar('web/icons/Icon-192.png', 192);
        await _gravar('web/icons/Icon-512.png', 512);
        await _gravar('web/icons/Icon-maskable-192.png', 192, escala: 0.8);
        await _gravar('web/icons/Icon-maskable-512.png', 512, escala: 0.8);
        await _gravar('web/favicon.png', 32);
      });
    },
    skip: Platform.environment['GERAR_ICONES'] != '1',
  );
}
