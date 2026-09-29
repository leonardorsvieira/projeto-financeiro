import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/env.dart';
import '../../lancamentos/application/lancamentos_providers.dart';
import '../../lancamentos/domain/lancamento.dart';
import '../data/bank_notification_parser.dart';
import '../data/ofx_parser_service.dart';
import '../data/open_finance_repository.dart';
import '../data/pluggy_open_finance_service.dart';
import '../domain/conta_bancaria_conectada.dart';
import '../domain/transacao_bancaria_importada.dart';

final openFinanceRepositoryProvider = Provider<OpenFinanceRepository>(
  (ref) => OpenFinanceRepository(),
);

final pluggyOpenFinanceServiceProvider = Provider<PluggyOpenFinanceService>(
  (ref) => PluggyOpenFinanceService(),
);

/// Se o servidor tem o Open Finance (Pluggy) configurado.
final pluggyConfiguradoProvider = FutureProvider<bool>(
  (ref) => ref.watch(pluggyOpenFinanceServiceProvider).verificarConfiguracao(),
);

/// Provider que gerencia a lista de contas bancárias vinculadas.
final contasConectadasProvider =
    NotifierProvider<ContasConectadasNotifier, AsyncValue<List<ContaBancariaConectada>>>(
  ContasConectadasNotifier.new,
);

class ContasConectadasNotifier
    extends Notifier<AsyncValue<List<ContaBancariaConectada>>> {
  @override
  AsyncValue<List<ContaBancariaConectada>> build() {
    _carregarContas();
    return const AsyncValue.loading();
  }

  Future<void> _carregarContas() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(openFinanceRepositoryProvider);
      final contas = await repo.getContasConectadas();
      state = AsyncValue.data(contas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> adicionarConta(ContaBancariaConectada conta) async {
    final repo = ref.read(openFinanceRepositoryProvider);
    await repo.adicionarConta(conta);
    await _carregarContas();
  }

  /// Remove a conexão de verdade (Pluggy + servidor) e depois do aparelho.
  Future<void> removerConta(String id) async {
    final conta = state.value?.where((c) => c.id == id).firstOrNull;
    final itemId = conta?.itemIdPluggy ?? id;
    if (!itemId.startsWith('banco_') && !itemId.startsWith('pluggy_item_')) {
      await ref.read(pluggyOpenFinanceServiceProvider).removerConexao(itemId);
    }
    final repo = ref.read(openFinanceRepositoryProvider);
    await repo.removerConta(id);
    await _carregarContas();
  }

  /// Remove todas as conexões do usuário (Pluggy + servidor + aparelho).
  /// Os lançamentos já importados continuam.
  Future<int> removerTodas() async {
    final removidas = await ref
        .read(pluggyOpenFinanceServiceProvider)
        .removerTodasConexoes();
    await salvarTodas(const []);
    return removidas;
  }

  Future<void> salvarTodas(List<ContaBancariaConectada> contas) async {
    final repo = ref.read(openFinanceRepositoryProvider);
    await repo.salvarContasConectadas(contas);
    state = AsyncValue.data(contas);
  }
}

/// Controla o estado de ativação da captura automática por notificações de bancos.
final capturaNotificacoesAtivaProvider =
    NotifierProvider<CapturaNotificacoesNotifier, bool>(
  CapturaNotificacoesNotifier.new,
);

class CapturaNotificacoesNotifier extends Notifier<bool> {
  @override
  bool build() {
    _carregar();
    return true;
  }

  Future<void> _carregar() async {
    final repo = ref.read(openFinanceRepositoryProvider);
    state = await repo.isCapturaNotificacoesAtiva();
  }

  Future<void> setAtivo(bool ativo) async {
    state = ativo;
    final repo = ref.read(openFinanceRepositoryProvider);
    await repo.setCapturaNotificacoesAtiva(ativo);
  }
}

/// Resultado retornado pela sincronização com a Pluggy.
class ResultadoSincronizacaoPluggy {
  final int contasSincronizadas;
  final int transacoesNovas;

  const ResultadoSincronizacaoPluggy({
    required this.contasSincronizadas,
    required this.transacoesNovas,
  });
}

/// Sincroniza todas as contas e transações da Pluggy em um só clique.
Future<ResultadoSincronizacaoPluggy> sincronizarComPluggy(WidgetRef ref) =>
    _sincronizar(ref.read, ref.invalidate);

/// Importa o histórico dos últimos 12 meses (uma vez; não duplica o que já
/// foi importado).
Future<ResultadoSincronizacaoPluggy> importarHistorico12Meses(WidgetRef ref) =>
    _sincronizar(ref.read, ref.invalidate, dias: 365);

/// Núcleo da sincronização, usado pelo botão (WidgetRef) e pela sincronização
/// automática (Ref de um Notifier). [dias] força a janela de busca.
Future<ResultadoSincronizacaoPluggy> _sincronizar(
  T Function<T>(ProviderListenable<T> provider) ler,
  void Function(ProviderOrFamily provider) invalidar, {
  int? dias,
}) async {
  final service = ler(pluggyOpenFinanceServiceProvider);
  final contasNotifier = ler(contasConectadasProvider.notifier);
  final contasAtuais = ler(contasConectadasProvider).value ?? [];

  // 1. Busca ou atualiza os bancos conectados no Pluggy
  final contas = await service.buscarItensConectados(
    contasExistentes: contasAtuais,
  );
  if (contas.isNotEmpty) {
    await contasNotifier.salvarTodas(contas);
  }

  final listaParaBuscarTransacoes = contas.isNotEmpty ? contas : contasAtuais;
  if (listaParaBuscarTransacoes.isEmpty) {
    return const ResultadoSincronizacaoPluggy(
      contasSincronizadas: 0,
      transacoesNovas: 0,
    );
  }

  // 2. Transações já importadas (para não duplicar), consultadas direto no
  // banco. (Esperar o stream de lançamentos travava: sem tela ouvindo, o
  // Riverpod pausa o provider e o future nunca completa.)
  final lancamentoRepo = ler(lancamentosRepositoryProvider);
  final idsExistentes = await lancamentoRepo.obsImportadasPluggy();

  // 3. Busca as transações: 30 dias na primeira vez; depois só a última
  // semana (o webhook e a sincronização periódica cobrem o resto) — cada
  // página conta na cota diária.
  final transacoes = await service.buscarTodasTransacoes(
    contas: listaParaBuscarTransacoes,
    desde: DateTime.now().subtract(
      Duration(days: dias ?? (idsExistentes.isEmpty ? 30 : 7)),
    ),
  );

  var transacoesImportadas = 0;
  for (final t in transacoes) {
    final obsTag = 'pluggy_id:${t.id}';
    if (idsExistentes.contains(obsTag)) continue;

    try {
      await lancamentoRepo.create(
        // A coluna aceita até 200 caracteres.
        descricao: t.descricao.length > 200
            ? t.descricao.substring(0, 200)
            : t.descricao,
        valorCents: t.valorCents,
        categoria: t.categoriaSugerida,
        formaPagamento: t.formaPagamento,
        data: t.data,
        tipo: t.isReceita ? TipoLancamento.receita : TipoLancamento.despesa,
        obs: obsTag,
      );
      transacoesImportadas++;
    } on PostgrestException catch (e) {
      // 23505: o webhook (ou outro aparelho) já importou esta transação.
      if (e.code != '23505') rethrow;
    }
    idsExistentes.add(obsTag);
  }

  // Atualiza os streams
  invalidar(lancamentosStreamProvider);

  return ResultadoSincronizacaoPluggy(
    contasSincronizadas: listaParaBuscarTransacoes.length,
    transacoesNovas: transacoesImportadas,
  );
}

/// Liga a sincronização automática só no app de verdade (com Supabase
/// configurado); nos testes fica desligada.
final sincronizacaoAutomaticaHabilitadaProvider = Provider<bool>(
  (ref) => AppEnv.supabaseUrl.isNotEmpty,
);

/// Sincroniza a Pluggy sozinho enquanto o app está aberto: ao entrar, a cada
/// [intervalo] e quando o app volta para a frente. O estado é o horário da
/// última sincronização bem-sucedida.
final sincronizacaoAutomaticaProvider =
    NotifierProvider<SincronizacaoAutomatica, DateTime?>(
  SincronizacaoAutomatica.new,
);

class SincronizacaoAutomatica extends Notifier<DateTime?> {
  static const intervalo = Duration(minutes: 30);
  static const intervaloMinimo = Duration(minutes: 5);

  bool _rodando = false;

  @override
  DateTime? build() {
    if (!ref.watch(sincronizacaoAutomaticaHabilitadaProvider)) return null;

    final timer = Timer.periodic(intervalo, (_) => sincronizar());
    final ciclo = AppLifecycleListener(onResume: sincronizar);
    ref.onDispose(() {
      timer.cancel();
      ciclo.dispose();
    });
    Future.microtask(sincronizar);
    return null;
  }

  Future<void> sincronizar() async {
    final ultima = state;
    if (_rodando ||
        (ultima != null &&
            DateTime.now().difference(ultima) < intervaloMinimo)) {
      return;
    }
    _rodando = true;
    try {
      if (!await ref.read(pluggyConfiguradoProvider.future)) return;
      final resultado = await _sincronizar(ref.read, ref.invalidate);
      state = DateTime.now();
      if (resultado.transacoesNovas > 0) {
        debugPrint(
          'Sincronização automática: ${resultado.transacoesNovas} nova(s).',
        );
      }
    } on Object catch (e) {
      debugPrint('Sincronização automática falhou: $e');
    } finally {
      _rodando = false;
    }
  }
}

/// Função utilitária para converter uma transação importada em um Lançamento do Meu Bolso.
Future<void> importarTransacaoParaLancamentos(
  WidgetRef ref,
  TransacaoBancariaImportada t,
) async {
  final lancamentoRepo = ref.read(lancamentosRepositoryProvider);

  await lancamentoRepo.create(
    descricao: t.descricao,
    valorCents: t.valorCents,
    categoria: t.categoriaSugerida,
    formaPagamento: t.formaPagamento,
    data: t.data,
    tipo: t.isReceita ? TipoLancamento.receita : TipoLancamento.despesa,
    obs: 'pluggy_id:${t.id}',
  );
}

/// Processa notificação bancária recebida em tempo real e insere o lançamento.
Future<TransacaoBancariaImportada?> processarNotificacaoBancariaEmTempoReal(
  WidgetRef ref, {
  required String appPackage,
  required String titulo,
  required String texto,
}) async {
  final capturaAtiva = ref.read(capturaNotificacoesAtivaProvider);
  if (!capturaAtiva) return null;

  final importada = BankNotificationParser.parseNotificacao(
    appPackageOuNome: appPackage,
    titulo: titulo,
    texto: texto,
  );

  if (importada != null) {
    await importarTransacaoParaLancamentos(ref, importada);
  }
  return importada;
}

/// Processa extrato OFX e insere todas as transações de uma só vez.
Future<int> importarExtratoOFX(
  WidgetRef ref,
  String conteudoOFX,
) async {
  final transacoes = OfxParserService.parseOFX(conteudoOFX);
  var importadas = 0;

  for (final t in transacoes) {
    await importarTransacaoParaLancamentos(ref, t);
    importadas++;
  }

  return importadas;
}
