import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/lembretes_controller.dart';
import '../application/preferencias_service.dart';

/// Abre o diálogo de preferências de lembretes (horário + dias antes).
/// Persiste via `LembretesController.alterarPreferencias` e mostra SnackBar.
Future<void> abrirPreferenciasLembretes(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = await ref.read(preferenciasLembretesProvider.future);
  if (!context.mounted) return;

  final resultado = await showDialog<PreferenciasLembretes>(
    context: context,
    builder: (context) => LembretesPreferenciasDialog(initial: prefs),
  );
  if (resultado == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(lembretesControllerProvider.notifier)
        .alterarPreferencias(resultado);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Lembretes: ${resultado.diasAntesNormalizado} '
          '${resultado.diasAntesNormalizado == 1 ? 'dia' : 'dias'} antes às '
          '${resultado.label}.',
        ),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível ajustar os lembretes.')),
    );
  }
}

class LembretesPreferenciasDialog extends StatefulWidget {
  const LembretesPreferenciasDialog({super.key, required this.initial});

  final PreferenciasLembretes initial;

  @override
  State<LembretesPreferenciasDialog> createState() =>
      _LembretesPreferenciasDialogState();
}

class _LembretesPreferenciasDialogState
    extends State<LembretesPreferenciasDialog> {
  late TimeOfDay _horario;
  late int _diasAntes;

  @override
  void initState() {
    super.initState();
    _horario =
        TimeOfDay(hour: widget.initial.hora, minute: widget.initial.minuto);
    _diasAntes = widget.initial.diasAntesNormalizado;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lembretes de vencimento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Horário do aviso'),
            trailing: Text(
              _horario.format(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              final horario = await showTimePicker(
                context: context,
                initialTime: _horario,
                helpText: 'Horário dos lembretes',
              );
              if (horario != null && mounted) {
                setState(() => _horario = horario);
              }
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Avisar dias antes'),
            subtitle: Text(
              _diasAntes == 0
                  ? 'Apenas no dia do vencimento'
                  : '$_diasAntes ${_diasAntes == 1 ? 'dia' : 'dias'} antes e no dia',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Diminuir',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _diasAntes > PreferenciasLembretes.diasAntesMin
                      ? () => setState(() => _diasAntes--)
                      : null,
                ),
                Text(
                  '$_diasAntes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: 'Aumentar',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _diasAntes < PreferenciasLembretes.diasAntesMax
                      ? () => setState(() => _diasAntes++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              PreferenciasLembretes(
                hora: _horario.hour,
                minuto: _horario.minute,
                diasAntes: _diasAntes,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}