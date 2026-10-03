import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../open_finance/application/open_finance_providers.dart';
import '../data/gemini_consultoria_repository.dart';
import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';
import 'dados_consultoria.dart';

final consultoriaRepositoryProvider = Provider<ConsultoriaRepository>(
  (ref) => GeminiConsultoriaRepository(),
);

final consultoriaRelogioProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Números do cliente para o guia (lançamentos, bancos e investimentos).
final dadosConsultoriaProvider = Provider<DadosConsultoria>((ref) {
  return montarDadosConsultoria(
    lancamentos: ref.watch(lancamentosStreamProvider).value ?? const [],
    investimentos: ref.watch(investimentosStreamProvider).value ?? const [],
    contas: ref.watch(contasConectadasProvider).value ?? const [],
    hoje: ref.watch(consultoriaRelogioProvider)(),
  );
});

/// Perfil escolhido na tela do guia (só na memória desta sessão).
final perfilInvestidorProvider =
    NotifierProvider<PerfilInvestidorNotifier, PerfilInvestidor>(
  PerfilInvestidorNotifier.new,
);

class PerfilInvestidorNotifier extends Notifier<PerfilInvestidor> {
  @override
  PerfilInvestidor build() => const PerfilInvestidor();

  void objetivo(ObjetivoInvestimento valor) =>
      state = state.copyWith(objetivo: valor);

  void prazo(PrazoInvestimento valor) => state = state.copyWith(prazo: valor);

  void risco(ToleranciaRisco valor) => state = state.copyWith(risco: valor);

  void observacao(String valor) => state = state.copyWith(observacao: valor);
}

/// Último guia gerado nesta sessão: `AsyncData(null)` antes do primeiro. Fica
/// guardado ao sair e voltar da tela (cada guia gasta cota de IA).
final guiaInvestimentosProvider =
    NotifierProvider<GuiaInvestimentosController, AsyncValue<GuiaInvestimentos?>>(
  GuiaInvestimentosController.new,
);

class GuiaInvestimentosController
    extends Notifier<AsyncValue<GuiaInvestimentos?>> {
  @override
  AsyncValue<GuiaInvestimentos?> build() => const AsyncData(null);

  Future<void> gerar() async {
    if (state.isLoading) return;
    final perfil = ref.read(perfilInvestidorProvider);
    if (!perfil.completo) return;
    final dados = ref.read(dadosConsultoriaProvider);

    state = const AsyncLoading();
    try {
      final guia = await ref.read(consultoriaRepositoryProvider).gerar(
            dadosCliente: dados.paraPrompt(),
            perfil: perfil,
          );
      if (!ref.mounted) return;
      state = AsyncData(guia);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }
}
