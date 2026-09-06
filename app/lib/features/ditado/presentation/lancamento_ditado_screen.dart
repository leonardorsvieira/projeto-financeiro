import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/domain/app_routes.dart';
import '../application/ditado_providers.dart';

class LancamentoDitadoScreen extends ConsumerStatefulWidget {
  const LancamentoDitadoScreen({super.key});

  @override
  ConsumerState<LancamentoDitadoScreen> createState() =>
      _LancamentoDitadoScreenState();
}

class _LancamentoDitadoScreenState
    extends ConsumerState<LancamentoDitadoScreen> {
  Timer? _temporizador;
  int _segundos = 0;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _ligarCronometro() {
    _temporizador?.cancel();
    _segundos = 0;
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  void _desligarCronometro() {
    _temporizador?.cancel();
    _temporizador = null;
    _segundos = 0;
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _gravar() async {
    await ref.read(ditadoControllerProvider.notifier).gravar();
    if (!mounted) return;
    final estado = ref.read(ditadoControllerProvider);
    if (estado is DitadoErro) {
      _desligarCronometro();
      _mostrarMensagem(estado.mensagem);
    }
  }

  Future<void> _parar() async {
    final controller = ref.read(ditadoControllerProvider.notifier);
    await controller.parar();
    if (!mounted) return;
    _desligarCronometro();
    final estado = ref.read(ditadoControllerProvider);
    switch (estado) {
      case DitadoSucesso(:final rascunho):
        controller.reiniciar();
        context.push(AppRoutes.confirmacaoDitado, extra: rascunho);
      case DitadoErro(:final mensagem):
        _mostrarMensagem(mensagem);
      default:
        break;
    }
  }

  void _aoApertar() {
    final estado = ref.read(ditadoControllerProvider);
    if (estado is DitadoGravando) return;
    _ligarCronometro();
    _gravar();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estado = ref.watch(ditadoControllerProvider);

    final (IconData icone, Color cor, String rotulo, String? detalhe,
        VoidCallback? acao) = switch (estado) {
      DitadoGravando() => (
          Icons.stop,
          tema.colorScheme.error,
          'Toque para parar',
          'Falando… $_segundos s',
          _parar,
        ),
      DitadoProcessando() => (
          Icons.hourglass_top,
          tema.colorScheme.primary,
          'Analisando…',
          'A IA está ouvindo o que você disse',
          null,
        ),
      _ => (
          Icons.mic_none,
          tema.colorScheme.primary,
          'Toque para gravar',
          null,
          _aoApertar,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Ditar lançamento')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  GestureDetector(
                    onTap: acao,
                    child: _BotaoMic(
                      cor: cor,
                      icone: icone,
                      tamanho: estado is DitadoGravando ? 160.0 : 128.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    rotulo,
                    style: tema.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (detalhe != null) ...[
                    Text(
                      detalhe,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(flex: 3),
                  Text(
                    'Fale o gasto. Ex.: "almoço quarenta reais com cartão".',
                    style: tema.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoMic extends StatelessWidget {
  const _BotaoMic({
    required this.cor,
    required this.icone,
    required this.tamanho,
  });

  final Color cor;
  final IconData icone;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.12),
      ),
      child: Icon(icone, size: 64, color: cor),
    );
  }
}