import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../application/acesso_providers.dart';
import '../domain/regras_acesso.dart';
import 'contato_vendedor.dart';

/// Portão de assinatura: conta sem acesso ativo (e que não é administradora)
/// fica aqui. Só os dados da própria conta (consultar, exportar, excluir) e os
/// documentos legais continuam abertos. A saída para a home é feita pelo
/// redirect do router, que reavalia o status quando ele muda.
class SemAcessoScreen extends ConsumerStatefulWidget {
  const SemAcessoScreen({super.key});

  @override
  ConsumerState<SemAcessoScreen> createState() => _SemAcessoScreenState();
}

class _SemAcessoScreenState extends ConsumerState<SemAcessoScreen> {
  bool _verificando = false;

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _verificarDeNovo() async {
    setState(() => _verificando = true);
    ref.invalidate(statusAcessoProvider);
    try {
      final status = await ref.read(statusAcessoProvider.future);
      // Se o acesso voltou, o router já levou à home e esta tela saiu.
      if (!mounted) return;
      if (status == null || !status.liberado) {
        _aviso(
          'Seu acesso ainda não está ativo. Se você já pagou, aguarde a '
          'liberação do vendedor.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _aviso(
        'Não foi possível verificar agora. Verifique a conexão e tente '
        'novamente.',
      );
    }
    if (mounted) setState(() => _verificando = false);
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
    final cores = CadernetaCores.of(context);
    final email = ref.watch(authControllerProvider).value?.email;
    final validoAte = ref.watch(statusAcessoProvider).value?.validoAte;
    final corpo = CadernetaTexto.corpo(
      size: 15,
      cor: cores.apagado,
    ).copyWith(height: 1.5);

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
                    Center(
                      child: PhosphorIcon(
                        Icones.seguranca,
                        size: 56,
                        color: Caderneta.ocre(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seu acesso não está ativo',
                      textAlign: TextAlign.center,
                      style: CadernetaTexto.display(size: 26),
                    ),
                    const SizedBox(height: 12),
                    if (validoAte != null) ...[
                      Text(
                        'Sua assinatura venceu em ${formatarData(validoAte)}.',
                        textAlign: TextAlign.center,
                        style: corpo,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Para continuar usando o Meu Bolso, fale com o vendedor.',
                      textAlign: TextAlign.center,
                      style: corpo,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Seus lançamentos continuam guardados. Em Meus dados '
                      'você pode consultá-los, exportar uma cópia ou excluir '
                      'a conta.',
                      textAlign: TextAlign.center,
                      style: CadernetaTexto.corpo(size: 14, cor: cores.apagado),
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Conta: $email',
                        textAlign: TextAlign.center,
                        style: CadernetaTexto.corpo(
                          size: 13,
                          cor: cores.apagado,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          falarComVendedor(context, emailConta: email),
                      icon: const PhosphorIcon(Icones.email),
                      label: const Text('Falar com o vendedor'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.privacidadeEDados),
                      icon: const PhosphorIcon(Icones.privacidade),
                      label: const Text('Meus dados'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _verificando ? null : _verificarDeNovo,
                      icon: _verificando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const PhosphorIcon(Icones.atualizar),
                      label: const Text('Já renovei — verificar de novo'),
                    ),
                    TextButton.icon(
                      onPressed: _sair,
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
