import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/privacidade_providers.dart';
import '../domain/exclusao_conta_repository.dart';

/// Pede a confirmação (digitar EXCLUIR) e apaga a conta no servidor. Devolve
/// true só se o servidor confirmou a exclusão; a limpeza do aparelho e a saída
/// ficam com quem chamou.
Future<bool> mostrarExcluirConta(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ExcluirContaDialog(),
  );
  return resultado ?? false;
}

class _ExcluirContaDialog extends ConsumerStatefulWidget {
  const _ExcluirContaDialog();

  @override
  ConsumerState<_ExcluirContaDialog> createState() =>
      _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends ConsumerState<_ExcluirContaDialog> {
  static const _palavra = 'EXCLUIR';

  final _controller = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _confirmado => _controller.text.trim() == _palavra;

  Future<void> _excluir() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(exclusaoContaRepositoryProvider).excluirConta();
      if (mounted) Navigator.of(context).pop(true);
    } on ExclusaoContaException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro =
            'Não foi possível excluir a conta agora. Verifique a conexão e '
            'tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: const Text('Excluir sua conta?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação é definitiva e não pode ser desfeita. Ao '
                'confirmar, apagamos:',
              ),
              const SizedBox(height: 8),
              for (final item in const [
                'seus lançamentos, metas e investimentos guardados no '
                    'servidor;',
                'as conexões com bancos feitas pelo Open Finance;',
                'os dados guardados neste aparelho (cartões, preferências e '
                    'lembretes).',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Se quiser guardar uma cópia, exporte seus dados antes.',
              ),
              const SizedBox(height: 8),
              const Text('Para confirmar, digite EXCLUIR.'),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                enabled: !_enviando,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Digite EXCLUIR'),
                onChanged: (_) => setState(() {}),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: (_confirmado && !_enviando) ? _excluir : null,
            child: _enviando
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onError,
                    ),
                  )
                : const Text('Excluir conta'),
          ),
        ],
      ),
    );
  }
}
