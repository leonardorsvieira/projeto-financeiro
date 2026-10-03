import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../investimentos/application/investimentos_providers.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../open_finance/application/open_finance_providers.dart';
import '../data/edge_indicadores_repository.dart';
import '../data/gemini_consultoria_repository.dart';
import '../data/supabase_guias_repository.dart';
import '../domain/guia_investimentos.dart';
import '../domain/indicadores_mercado.dart';
import '../domain/perfil_investidor.dart';
import 'dados_consultoria.dart';

final consultoriaRepositoryProvider = Provider<ConsultoriaRepository>(
  (ref) => GeminiConsultoriaRepository(),
);

final indicadoresRepositoryProvider = Provider<IndicadoresRepository>(
  (ref) => EdgeIndicadoresRepository(),
);

final guiasRepositoryProvider = Provider<GuiasRepository>(
  (ref) => SupabaseGuiasRepository(),
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

/// Perfil e último guia guardados na conta: as perguntas são feitas uma vez
/// e o guia continua lá ao voltar à tela, em outro aparelho ou depois do
/// logout.
final guiaSalvoProvider = AsyncNotifierProvider<GuiaSalvoNotifier, GuiaSalvo>(
  GuiaSalvoNotifier.new,
);

class GuiaSalvoNotifier extends AsyncNotifier<GuiaSalvo> {
  @override
  Future<GuiaSalvo> build() => ref.read(guiasRepositoryProvider).carregar();

  Future<void> salvarPerfil(PerfilInvestidor perfil) async {
    await ref.read(guiasRepositoryProvider).salvarPerfil(perfil);
    if (!ref.mounted) return;
    state = AsyncData(GuiaSalvo(perfil: perfil, guia: state.value?.guia));
  }

  /// Mostra o guia na hora e o guarda na conta. Se guardar falhar, ele fica
  /// na tela nesta sessão.
  Future<void> salvarGuia(GuiaInvestimentos guia) async {
    state = AsyncData(GuiaSalvo(perfil: state.value?.perfil, guia: guia));
    try {
      await ref.read(guiasRepositoryProvider).salvarGuia(guia);
    } on Object catch (e) {
      debugPrint('Guardar o guia falhou: $e');
    }
  }
}

/// Rascunho do perfil enquanto o usuário responde ou altera as perguntas.
final perfilInvestidorProvider =
    NotifierProvider<PerfilInvestidorNotifier, PerfilInvestidor>(
  PerfilInvestidorNotifier.new,
);

class PerfilInvestidorNotifier extends Notifier<PerfilInvestidor> {
  @override
  PerfilInvestidor build() => const PerfilInvestidor();

  /// Começa a alteração a partir do perfil salvo.
  void carregar(PerfilInvestidor perfil) => state = perfil;

  void objetivo(ObjetivoInvestimento valor) =>
      state = state.copyWith(objetivo: valor);

  void prazo(PrazoInvestimento valor) => state = state.copyWith(prazo: valor);

  void risco(ToleranciaRisco valor) => state = state.copyWith(risco: valor);

  void observacao(String valor) => state = state.copyWith(observacao: valor);
}

/// Geração de um relatório: carregando / erro. O relatório em si fica em
/// [guiaSalvoProvider].
final geracaoGuiaProvider =
    NotifierProvider<GeracaoGuiaController, AsyncValue<void>>(
  GeracaoGuiaController.new,
);

class GeracaoGuiaController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  /// Gera um relatório com o [perfil] e os dados de agora (lançamentos,
  /// bancos e investimentos) e o guarda na conta no lugar do anterior.
  Future<void> gerar(PerfilInvestidor perfil) async {
    if (state.isLoading || !perfil.completo) return;

    state = const AsyncLoading();
    try {
      final dados = await _dadosCarregados();
      if (!ref.mounted) return;
      // Sem indicadores (fonte fora do ar) o guia sai mesmo assim.
      final indicadores = await ref.read(indicadoresRepositoryProvider).buscar();
      if (!ref.mounted) return;
      final guia = await ref.read(consultoriaRepositoryProvider).gerar(
            dadosCliente: dados.paraPrompt(),
            perfil: perfil,
            indicadores: indicadores?.paraPrompt(),
          );
      if (!ref.mounted) return;
      await ref
          .read(guiaSalvoProvider.notifier)
          .salvarGuia(guia.comFontes(indicadores?.fontes ?? const []));
      if (!ref.mounted) return;
      state = const AsyncData<void>(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  /// Espera lançamentos e investimentos chegarem (a tela do guia mantém
  /// esses streams ouvidos): sem isso, um guia pedido logo ao abrir sairia
  /// como "nenhum lançamento registrado".
  Future<DadosConsultoria> _dadosCarregados() async {
    try {
      await Future.wait([
        ref.read(lancamentosStreamProvider.future),
        ref.read(investimentosStreamProvider.future),
      ]).timeout(const Duration(seconds: 10));
    } on Object catch (e) {
      debugPrint('Dados do guia incompletos: $e');
    }
    return ref.read(dadosConsultoriaProvider);
  }
}
