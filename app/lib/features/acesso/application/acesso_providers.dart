import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/supabase_acesso_repository.dart';
import '../domain/acesso.dart';
import '../domain/acesso_repository.dart';

/// Relógio do módulo de acesso (injetável nos testes). Datas de validade são
/// dias de calendário, então só a data de hoje importa.
final acessoRelogioProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final acessoRepositoryProvider = Provider<AcessoRepository>(
  (ref) => SupabaseAcessoRepository(agora: ref.watch(acessoRelogioProvider)),
);

/// Status de acesso da conta logada; null = sem sessão. Refaz a consulta no
/// login e na troca de conta (não a cada renovação do token de sessão). O
/// retry automático fica desligado: o próprio portão decide o que fazer com a
/// falha, e o botão "Já renovei" consulta de novo.
final statusAcessoProvider = FutureProvider<StatusAcesso?>((ref) async {
  final (logado, _) = ref.watch(
    authControllerProvider.select(
      (a) => (a.value?.isAuthenticated ?? false, a.value?.email),
    ),
  );
  if (!logado) return null;
  return ref.watch(acessoRepositoryProvider).status();
}, retry: (_, _) => null);

/// Lista de acessos para a tela do administrador. Sem retry automático: a
/// tela mostra o erro e oferece "Tentar de novo".
final acessosAdminProvider = FutureProvider<List<Acesso>>(
  (ref) => ref.watch(acessoRepositoryProvider).listar(),
  retry: (_, _) => null,
);

enum DecisaoAcesso { aguardando, liberado, bloqueado }

/// Decide o portão a partir do estado do [statusAcessoProvider].
///
/// Falha aberta SÓ na primeira consulta: o portão é UX, quem garante o acesso
/// é o servidor (RLS RESTRICTIVE + Edge Functions). Uma falha de rede não
/// trava quem pagou e também não dá nada a quem não pagou. Pelo mesmo motivo o
/// app pode ser publicado antes da migration (RPC inexistente -> liberado).
/// Depois que há um status conhecido, ele vale até a próxima consulta dar certo
/// (inclusive durante uma recarga ou depois de uma recarga com erro).
DecisaoAcesso decidirAcesso(AsyncValue<StatusAcesso?> estado) {
  final status = estado.value;
  if (status != null) {
    return status.liberado ? DecisaoAcesso.liberado : DecisaoAcesso.bloqueado;
  }
  if (estado.hasError) return DecisaoAcesso.liberado;
  return DecisaoAcesso.aguardando;
}
