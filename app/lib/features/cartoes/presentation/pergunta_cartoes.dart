import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/icones.dart';
import '../application/cartoes_providers.dart';
import 'cartoes_screen.dart';

/// Pergunta quais cartões de crédito o usuário tem, sugerindo os que vieram do
/// banco. Quem chama decide quando (sem cartões e pergunta não respondida).
Future<void> perguntarCartoes(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const PerguntaCartoesDialog(),
  );
}

class PerguntaCartoesDialog extends ConsumerWidget {
  const PerguntaCartoesDialog({super.key});

  Future<void> _responder(BuildContext context, WidgetRef ref) async {
    final navegador = Navigator.of(context);
    try {
      await ref.read(cartoesRepositoryProvider).marcarPerguntaRespondida();
    } catch (_) {
      // Sem internet: a pergunta volta na próxima abertura, sem prejuízo.
    }
    navegador.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartoes = ref.watch(cartoesControllerProvider).value ?? const [];
    final sugestoes = ref.watch(sugestoesCartoesProvider);

    return AlertDialog(
      title: const Text('Quais cartões de crédito você usa?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cadastre seus cartões para o Meu Bolso separar os gastos de '
              'cada um e lembrar do vencimento das faturas.',
            ),
            if (cartoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Já cadastrados:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cartoes)
                    Chip(
                      avatar: const PhosphorIcon(Icones.cartao, size: 16),
                      label: Text(c.nome),
                    ),
                ],
              ),
            ],
            if (sugestoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Encontrados no seu banco — toque para cadastrar:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final nome in sugestoes)
                    ActionChip(
                      avatar: const PhosphorIcon(Icones.adicionar, size: 16),
                      label: Text(nome),
                      onPressed: () =>
                          abrirFormularioCartao(context, nomeSugerido: nome),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => abrirFormularioCartao(context),
              icon: const PhosphorIcon(Icones.adicionar),
              label: Text(
                cartoes.isEmpty ? 'Adicionar cartão' : 'Adicionar outro cartão',
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (cartoes.isEmpty) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          TextButton(
            onPressed: () => _responder(context, ref),
            child: const Text('Não uso cartão de crédito'),
          ),
        ] else
          FilledButton(
            onPressed: () => _responder(context, ref),
            child: const Text('Pronto'),
          ),
      ],
    );
  }
}
