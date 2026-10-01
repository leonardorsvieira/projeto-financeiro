import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/aviso_login.dart';
import '../../home/domain/app_routes.dart';
import '../../lancamentos/application/exportar_service.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../seguranca/application/limpeza_local.dart';
import '../application/privacidade_providers.dart';
import '../domain/controlador.dart';
import '../domain/documento_legal.dart';
import 'excluir_conta_dialog.dart';

/// Central de privacidade: documentos legais, exportação dos dados (LGPD
/// art. 18, V), contato com o responsável e exclusão da conta (art. 18, VI).
class PrivacidadeDadosScreen extends ConsumerStatefulWidget {
  const PrivacidadeDadosScreen({super.key});

  @override
  ConsumerState<PrivacidadeDadosScreen> createState() =>
      _PrivacidadeDadosScreenState();
}

class _PrivacidadeDadosScreenState
    extends ConsumerState<PrivacidadeDadosScreen> {
  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _exportar() async {
    try {
      final todos = await ref.read(lancamentosStreamProvider.future);
      if (!mounted) return;
      if (todos.isEmpty) {
        _aviso('Ainda não há lançamentos para exportar.');
        return;
      }
      final csv = ExportarService.gerarCSV(todos);
      // utf8.encode (e não codeUnits) para preservar os acentos.
      final bytes = Uint8List.fromList(utf8.encode(csv));
      await ref.read(compartilharArquivoProvider)(
        bytes,
        'MeuBolso_meus_lancamentos.csv',
      );
    } catch (_) {
      if (mounted) _aviso('Não foi possível exportar agora. Tente novamente.');
    }
  }

  Future<void> _falarComResponsavel() async {
    final assunto = Uri.encodeComponent('Meu Bolso: privacidade');
    var abriu = false;
    try {
      abriu = await launchUrl(
        Uri.parse('mailto:$emailPrivacidade?subject=$assunto'),
      );
    } catch (_) {
      abriu = false;
    }
    if (!abriu && mounted) _aviso('Escreva para $emailPrivacidade.');
  }

  Future<void> _excluirConta() async {
    if (!await mostrarExcluirConta(context)) return;
    // O servidor já apagou a conta. Limpa o aparelho, deixa o aviso para o
    // login da próxima sessão e sai. A sessão local termina antes da chamada
    // ao servidor, então um erro de rede no signOut não impede nada.
    await ref.read(limparDadosLocaisProvider)();
    AvisoProximaSessao.definir('Conta excluída.');
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {}
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cores = CadernetaCores.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e dados')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Seus dados são seus. Aqui você consulta os documentos, leva '
              'uma cópia dos seus lançamentos ou encerra a conta.',
              style: CadernetaTexto.corpo(
                size: 15,
                cor: cores.apagado,
              ).copyWith(height: 1.5),
            ),
          ),
          ListTile(
            leading: const PhosphorIcon(Icones.privacidade),
            title: const Text('Política de Privacidade'),
            subtitle: const Text('Quais dados tratamos e por quê'),
            trailing: const PhosphorIcon(Icones.proximo),
            onTap: () => context.push(AppRoutes.privacidade),
          ),
          ListTile(
            leading: const PhosphorIcon(Icones.termos),
            title: const Text('Termos de Uso'),
            subtitle: const Text('As regras de uso do Meu Bolso'),
            trailing: const PhosphorIcon(Icones.proximo),
            onTap: () => context.push(AppRoutes.termos),
          ),
          ListTile(
            leading: const PhosphorIcon(Icones.exportar),
            title: const Text('Exportar meus dados'),
            subtitle: const Text('Planilha (CSV) com todos os seus lançamentos'),
            onTap: _exportar,
          ),
          ListTile(
            leading: const PhosphorIcon(Icones.email),
            title: const Text('Falar com o responsável'),
            subtitle: const Text(emailPrivacidade),
            onTap: _falarComResponsavel,
          ),
          const Divider(height: 32),
          ListTile(
            leading: PhosphorIcon(
              Icones.excluirConta,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Excluir minha conta',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Apaga seus dados de forma definitiva'),
            onTap: _excluirConta,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Documentos na versão de ${formatarVersao(versaoDocumentos)}.',
              style: CadernetaTexto.corpo(size: 13, cor: cores.apagado),
            ),
          ),
        ],
      ),
    );
  }
}
