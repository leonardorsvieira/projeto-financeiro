import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> removerConta(String id) async {
    final repo = ref.read(openFinanceRepositoryProvider);
    await repo.removerConta(id);
    await _carregarContas();
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

/// Função utilitária para converter uma transação importada em um Lançamento do Meu Bolso.
Future<void> importarTransacaoParaLancamentos(
  WidgetRef ref,
  TransacaoBancariaImportada t,
) async {
  final lancamentoRepo = ref.read(lancamentosRepositoryProvider);
  final agora = DateTime.now();

  await lancamentoRepo.create(
    descricao: t.descricao,
    valorCents: t.valorCents,
    categoria: t.categoriaSugerida,
    formaPagamento: t.formaPagamento,
    data: t.data,
    tipo: t.isReceita ? TipoLancamento.receita : TipoLancamento.despesa,
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
