import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../auth/application/auth_controller.dart';
import '../application/acesso_providers.dart';
import '../domain/regras_acesso.dart';
import 'contato_vendedor.dart';

/// Aviso no topo do Resumo quando a assinatura vence em 0 a 5 dias. Sem prazo
/// ou administrador não vê nada.
class AvisoVencimentoAcesso extends ConsumerWidget {
  const AvisoVencimentoAcesso({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusAcessoProvider).value;
    if (status == null) return const SizedBox.shrink();
    final texto = textoAvisoVencimento(
      status,
      ref.watch(acessoRelogioProvider)(),
    );
    if (texto == null) return const SizedBox.shrink();

    final ocre = Caderneta.ocre(context);
    final email = ref.watch(authControllerProvider).value?.email;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: ocre.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              PhosphorIcon(Icones.vencimento, color: ocre),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
              TextButton(
                onPressed: () => falarComVendedor(context, emailConta: email),
                child: const Text('Renovar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
