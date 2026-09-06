import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final email = auth.maybeWhen(
      data: (s) => s.email,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Bolso'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Meu Bolso', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Você está logado como',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  email ?? '—',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Em breve — seus lançamentos aparecem aqui. (Fase 2)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}