import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tenta abrir a página de autorização da Pluggy. No navegador, a abertura
/// automática costuma ser barrada pelo bloqueador de pop-ups quando acontece
/// segundos depois do toque (o app espera a Pluggy gerar o link); nesse caso
/// devolve false e a tela oferece um botão "Abrir".
Future<bool> abrirAutorizacaoPluggy(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

SnackBar snackBarAbrirAutorizacao(Uri url) {
  return SnackBar(
    content: const Text(
      'Autorização pronta! Toque em "Abrir", clique em "Permitir" no '
      'meu.pluggy.ai e depois em "Sincronizar Agora".',
    ),
    backgroundColor: Colors.purple.shade700,
    duration: const Duration(seconds: 60),
    action: SnackBarAction(
      label: 'Abrir',
      textColor: Colors.white,
      onPressed: () => launchUrl(url, mode: LaunchMode.externalApplication),
    ),
  );
}
