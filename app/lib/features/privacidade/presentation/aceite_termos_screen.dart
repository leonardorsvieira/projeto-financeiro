import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../domain/controlador.dart';
import '../domain/documento_legal.dart';
import 'destaques_privacidade.dart';

/// Portão bloqueante: conta autenticada cujo aceite não é da versão vigente
/// dos documentos só segue depois de aceitar (ou sai). A navegação após o
/// aceite é feita pelo redirect do router, que enxerga o novo `termosVersao`.
class AceiteTermosScreen extends ConsumerStatefulWidget {
  const AceiteTermosScreen({super.key});

  @override
  ConsumerState<AceiteTermosScreen> createState() => _AceiteTermosScreenState();
}

class _AceiteTermosScreenState extends ConsumerState<AceiteTermosScreen> {
  bool _enviando = false;
  String? _erro;

  Future<void> _aceitar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).aceitarTermos();
      if (mounted) setState(() => _enviando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro =
            'Não foi possível registrar o aceite. Verifique a conexão e '
            'tente novamente.';
      });
    }
  }

  Future<void> _sair() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {
      // A sessão local já termina antes da chamada ao servidor.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cores = CadernetaCores.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Bolso'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Antes de continuar',
                      style: CadernetaTexto.display(size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atualizamos os Termos de Uso e a Política de '
                      'Privacidade do Meu Bolso (versão de '
                      '${formatarVersao(versaoDocumentos)}). Para seguir '
                      'usando o app, leia e aceite os documentos.',
                      style: CadernetaTexto.corpo(
                        size: 15,
                        cor: cores.apagado,
                      ).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const DestaquesPrivacidade(),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _enviando
                              ? null
                              : () => context.push(AppRoutes.termos),
                          icon: const PhosphorIcon(Icones.termos),
                          label: const Text('Termos de Uso'),
                        ),
                        TextButton.icon(
                          onPressed: _enviando
                              ? null
                              : () => context.push(AppRoutes.privacidade),
                          icon: const PhosphorIcon(Icones.privacidade),
                          label: const Text('Política de Privacidade'),
                        ),
                      ],
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erro!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _enviando ? null : _aceitar,
                      child: _enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Aceitar e continuar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _enviando ? null : _sair,
                      icon: const PhosphorIcon(Icones.sair),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
