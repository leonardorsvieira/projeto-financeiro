import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/biometria_providers.dart';

class BiometricLockWrapper extends ConsumerStatefulWidget {
  const BiometricLockWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends ConsumerState<BiometricLockWrapper>
    with WidgetsBindingObserver {
  bool _estaBloqueado = false;
  bool _autenticando = false;
  bool _jaVerificouColdStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarBloqueioInicial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final isAtivo = ref.read(bloqueioBiometricoAtivoProvider).value ?? false;
      if (isAtivo) {
        setState(() {
          _estaBloqueado = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_estaBloqueado && !_autenticando) {
        _solicitarAutenticacao();
      }
    }
  }

  Future<void> _verificarBloqueioInicial() async {
    if (_jaVerificouColdStart) return;
    _jaVerificouColdStart = true;
    final repo = ref.read(biometriaRepositoryProvider);
    final isAtivo = await repo.isBloqueioAtivo();
    if (isAtivo && mounted) {
      setState(() {
        _estaBloqueado = true;
      });
      await _solicitarAutenticacao();
    }
  }

  Future<void> _solicitarAutenticacao() async {
    if (_autenticando) return;
    setState(() => _autenticando = true);
    final repo = ref.read(biometriaRepositoryProvider);

    try {
      final sucesso = await repo.autenticar(
        motivo: 'Desbloqueie o Meu Bolso para continuar',
      );
      if (sucesso && mounted) {
        setState(() {
          _estaBloqueado = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _autenticando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_estaBloqueado) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: theme.scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Meu Bolso Bloqueado',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Autentique-se com sua impressão digital ou biometria para acessar suas finanças.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _autenticando ? null : _solicitarAutenticacao,
                  icon: const Icon(Icons.lock_open),
                  label: Text(_autenticando ? 'Aguardando digital...' : 'Desbloquear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
