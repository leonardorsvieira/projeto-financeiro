import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/biometria_providers.dart';

Future<void> mostrarDialogoBloqueioBiometrico(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _BloqueioBiometricoDialog(),
  );
}

class _BloqueioBiometricoDialog extends ConsumerStatefulWidget {
  const _BloqueioBiometricoDialog();

  @override
  ConsumerState<_BloqueioBiometricoDialog> createState() =>
      __BloqueioBiometricoDialogState();
}

class __BloqueioBiometricoDialogState
    extends ConsumerState<_BloqueioBiometricoDialog> {
  bool _carregando = false;
  bool _disponivel = true;

  @override
  void initState() {
    super.initState();
    _verificarDisponibilidade();
  }

  Future<void> _verificarDisponibilidade() async {
    final repo = ref.read(biometriaRepositoryProvider);
    final disponivel = await repo.isBiometricsAvailable();
    if (mounted) {
      setState(() => _disponivel = disponivel);
    }
  }

  Future<void> _toggleBloqueio(bool novoValor) async {
    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final sucesso = await ref
          .read(bloqueioBiometricoAtivoProvider.notifier)
          .setBloqueioAtivo(novoValor);

      if (sucesso) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              novoValor
                  ? 'Bloqueio por biometria ativado com sucesso!'
                  : 'Bloqueio por biometria desativado.',
            ),
          ),
        );
        nav.pop();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Autenticação cancelada ou não reconhecida.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoBloqueio = ref.watch(bloqueioBiometricoAtivoProvider);
    final isAtivo = estadoBloqueio.value ?? false;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.fingerprint),
          SizedBox(width: 8),
          Text('Segurança e Biometria'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ao ativar o bloqueio por biometria, o Meu Bolso solicitará sua digital ou biometria facial sempre que o aplicativo for aberto ou retornar do segundo plano.',
          ),
          const SizedBox(height: 16),
          if (!_disponivel) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biometria ou senha do dispositivo não configurada no celular.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bloquear com biometria'),
            subtitle: Text(
              isAtivo ? 'Ativado' : 'Desativado',
              style: const TextStyle(fontSize: 12),
            ),
            value: isAtivo,
            onChanged: (_carregando || !_disponivel)
                ? null
                : (valor) => _toggleBloqueio(valor),
          ),
          if (_carregando) const Center(child: CircularProgressIndicator()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
