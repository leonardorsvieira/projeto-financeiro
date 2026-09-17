import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_controller.dart';

void mostrarDialogoSelecaoTema(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ThemeSelectorDialog(),
  );
}

class _ThemeSelectorDialog extends ConsumerWidget {
  const _ThemeSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeControllerProvider);
    final notifier = ref.read(themeControllerProvider.notifier);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.palette_outlined),
          SizedBox(width: 8),
          Text('Aparência & Tema'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Sistema'),
            subtitle: const Text('Seguir tema padrão do celular'),
            secondary: const Icon(Icons.brightness_auto_outlined),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                notifier.definirTema(mode);
                Navigator.of(context).pop();
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Claro'),
            subtitle: const Text('Tema com fundo claro'),
            secondary: const Icon(Icons.light_mode_outlined),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                notifier.definirTema(mode);
                Navigator.of(context).pop();
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Escuro'),
            subtitle: const Text('Tema com fundo escuro'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                notifier.definirTema(mode);
                Navigator.of(context).pop();
              }
            },
          ),
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
