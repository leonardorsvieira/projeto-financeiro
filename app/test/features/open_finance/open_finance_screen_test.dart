import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/open_finance/application/open_finance_providers.dart';
import 'package:meubolso/features/open_finance/data/pluggy_open_finance_service.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';
import 'package:meubolso/features/open_finance/domain/transacao_bancaria_importada.dart';
import 'package:meubolso/features/open_finance/presentation/open_finance_screen.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../support/fake_investimentos_repository.dart';
import '../../support/fake_lancamentos_repository.dart';

final _conta = ContaBancariaConectada(
  id: 'item-1',
  nomeBanco: 'Nubank',
  tipoConta: 'Conta',
  corHex: '#8A05BE',
  ultimoSync: DateTime(2026, 10, 3, 9),
);

/// Pluggy falsa: registra a janela de cada busca de transações.
class _PluggyFalsa extends PluggyOpenFinanceService {
  _PluggyFalsa({this.falharHistorico = false});

  final bool falharHistorico;
  final janelas = <int>[];
  int buscasDeInvestimentos = 0;

  @override
  Future<bool> verificarConfiguracao() async => true;

  @override
  Future<List<ContaBancariaConectada>> buscarItensConectados({
    List<ContaBancariaConectada> contasExistentes = const [],
  }) async =>
      [_conta];

  @override
  Future<List<TransacaoBancariaImportada>> buscarTodasTransacoes({
    List<ContaBancariaConectada>? contas,
    DateTime? desde,
    List<String> nomesProprios = const [],
  }) async {
    final dias = DateTime.now().difference(desde!).inHours / 24;
    janelas.add(dias.round());
    if (dias > 300 && falharHistorico) throw Exception('cota');
    // Uma transação recente e uma antiga (só a busca de 12 meses traz).
    return [
      _tx('recente', DateTime.now().subtract(const Duration(days: 2))),
      if (dias > 300)
        _tx('antiga', DateTime.now().subtract(const Duration(days: 200))),
    ];
  }

  @override
  Future<InvestimentosOpenFinance> buscarInvestimentos(
    List<ContaBancariaConectada> contas,
  ) async {
    buscasDeInvestimentos++;
    return const InvestimentosOpenFinance(investimentos: [], completo: true);
  }

  static TransacaoBancariaImportada _tx(String id, DateTime data) =>
      TransacaoBancariaImportada(
        id: id,
        nomeBanco: 'Nubank',
        descricao: 'Compra $id',
        valorCents: 1000,
        isReceita: false,
        formaPagamento: 'Pix',
        data: data,
        origem: OrigemTransacaoBancaria.openFinance,
      );
}

Future<FakeLancamentosRepository> _pump(
  WidgetTester tester,
  _PluggyFalsa pluggy,
) async {
  SharedPreferences.setMockInitialValues({
    'open_finance_contas_v1': jsonEncode([_conta.toMap()]),
  });
  final lancamentos = FakeLancamentosRepository();
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pluggyOpenFinanceServiceProvider.overrideWithValue(pluggy),
        lancamentosRepositoryProvider.overrideWithValue(lancamentos),
        investimentosRepositoryProvider.overrideWithValue(
          FakeInvestimentosRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const OpenFinanceScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return lancamentos;
}

void main() {
  testWidgets('"Sincronizar agora" sincroniza e, em seguida, importa os '
      'últimos 12 meses; não há mais botão separado', (tester) async {
    final pluggy = _PluggyFalsa();
    final lancamentos = await _pump(tester, pluggy);

    expect(find.text('Importar últimos 12 meses'), findsNothing);

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    // Primeiro a sincronização normal (30 dias na 1ª vez), depois 365 dias.
    expect(pluggy.janelas, [30, 365]);
    // O Patrimônio é atualizado uma vez só (na sincronização).
    expect(pluggy.buscasDeInvestimentos, 1);
    // A recente entra na 1ª etapa; a antiga, no histórico; nada duplica.
    expect(lancamentos.items.map((l) => l.descricao).toList()..sort(),
        ['Compra antiga', 'Compra recente']);
    expect(
      find.textContaining('2 transação(ões) nova(s) importada(s), com o '
          'histórico dos últimos 12 meses'),
      findsOneWidget,
    );
  });

  testWidgets('falha no histórico não desfaz a sincronização', (tester) async {
    final pluggy = _PluggyFalsa(falharHistorico: true);
    final lancamentos = await _pump(tester, pluggy);

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(pluggy.janelas, [30, 365]);
    expect(lancamentos.items.map((l) => l.descricao), ['Compra recente']);
    expect(
      find.textContaining('não pôde ser importado agora'),
      findsOneWidget,
    );
  });
}
