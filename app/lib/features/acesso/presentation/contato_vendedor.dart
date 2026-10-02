import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/regras_acesso.dart';

/// Abre o e-mail para o vendedor pedir a renovação. Se o aparelho não abrir o
/// app de e-mail, mostra o endereço para a pessoa escrever por conta própria.
Future<void> falarComVendedor(
  BuildContext context, {
  String? emailConta,
}) async {
  final assunto = Uri.encodeComponent('Meu Bolso: renovar acesso');
  final corpo = (emailConta == null || emailConta.isEmpty)
      ? ''
      : '&body=${Uri.encodeComponent('Olá! Quero renovar meu acesso ao Meu Bolso. Minha conta: $emailConta.')}';
  var abriu = false;
  try {
    abriu = await launchUrl(
      Uri.parse('mailto:$emailVendedor?subject=$assunto$corpo'),
    );
  } catch (_) {
    abriu = false;
  }
  if (!abriu && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Escreva para $emailVendedor.')));
  }
}
