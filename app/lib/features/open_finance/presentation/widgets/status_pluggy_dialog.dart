import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/open_finance_providers.dart';

/// Mostra se o Open Finance está disponível. As credenciais da Pluggy ficam só
/// no servidor (Edge Function), nunca no aparelho.
void mostrarDialogoStatusPluggy(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _StatusPluggyDialog(),
  );
}

class _StatusPluggyDialog extends ConsumerWidget {
  const _StatusPluggyDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pluggyConfiguradoProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Open Finance'),
      content: status.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Text(
          'Não foi possível verificar o servidor. Confira sua conexão.',
        ),
        data: (configurado) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  configurado ? Icons.verified_user : Icons.cloud_off,
                  color: configurado
                      ? Colors.green.shade600
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    configurado
                        ? 'Disponível'
                        : 'Não configurado no servidor',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              configurado
                  ? 'A conexão com a Pluggy é feita pelo servidor do Meu Bolso. '
                      'Nenhuma chave fica no aparelho e só você vê os bancos '
                      'que conectou.'
                  : 'O administrador precisa cadastrar as credenciais da Pluggy '
                      'nos secrets do Supabase.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => ref.invalidate(pluggyConfiguradoProvider),
          child: const Text('Verificar de novo'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
