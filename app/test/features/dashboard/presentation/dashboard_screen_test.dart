import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meubolso/features/dashboard/presentation/dashboard_screen.dart';
import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/metas/application/metas_providers.dart';
import 'package:meubolso/features/metas/domain/meta.dart';

import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_lancamentos_repository.dart';
import '../../../support/fake_metas_repository.dart';
import '../../../support/fake_movimentos_investimento_repository.dart';

Lancamento _lanc({
  required String id,
  required int valorCents,
  required DateTime data,
  String categoria = 'Outros',
  DateTime? vencimento,
  TipoLancamento tipo = TipoLancamento.despesa,
}) {
  final agora = DateTime.now();
  return Lancamento(
    id: id,
    descricao: id,
    categoria: categoria,
    valorCents: valorCents,
    formaPagamento: 'Pix',
    data: data,
    vencimento: vencimento,
    tipo: tipo,
    createdAt: agora,
    updatedAt: agora,
  );
}

Future<void> _pump(
  WidgetTester tester,
  FakeLancamentosRepository repo, {
  FakeMetasRepository? metasRepo,
  FakeInvestimentosRepository? investimentosRepo,
}) async {
  await tester.pumpWidget(
    ProviderScopeContainer(
      repo: repo,
      metasRepo: metasRepo ?? FakeMetasRepository(),
      investimentosRepo:
          investimentosRepo ?? FakeInvestimentosRepository(),
      child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

class ProviderScopeContainer extends StatelessWidget {
  const ProviderScopeContainer({
    super.key,
    required this.repo,
    required this.metasRepo,
    required this.investimentosRepo,
    required this.child,
  });

  final FakeLancamentosRepository repo;
  final FakeMetasRepository metasRepo;
  final FakeInvestimentosRepository investimentosRepo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        lancamentosRepositoryProvider.overrideWithValue(repo),
        metasRepositoryProvider.overrideWithValue(metasRepo),
        investimentosRepositoryProvider.overrideWithValue(investimentosRepo),
        movimentosInvestimentoRepositoryProvider
            .overrideWithValue(FakeMovimentosInvestimentoRepository()),
      ],
      child: child,
    );
  }
}

void main() {
  testWidgets('DashboardScreen mostra saldo do mês (entradas − saídas)',
      (tester) async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final outroMes = DateTime(
      agora.month == 1 ? agora.year + 1 : agora.year,
      agora.month == 1 ? 2 : agora.month - 1,
    );

    final repo = FakeLancamentosRepository([
      _lanc(
        id: 'Salário',
        valorCents: 300000,
        data: mes.add(const Duration(days: 3)),
        tipo: TipoLancamento.receita,
      ),
      _lanc(id: 'Mercado', valorCents: 10000, data: mes.add(const Duration(days: 3))),
      _lanc(
        id: 'Conta luz',
        valorCents: 5000,
        data: outroMes,
        vencimento: mes.add(const Duration(days: 10)),
      ),
    ]);

    await _pump(tester, repo);

    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Previsto no mês: R\$ 50,00'), findsOneWidget);
    expect(find.text('R\$ 3.000,00'), findsWidgets); // entradas
    expect(find.text('R\$ 100,00'), findsWidgets); // saídas

    await tester.scrollUntilVisible(find.text('Conta luz'), 100);
    expect(find.text('Conta luz'), findsOneWidget);
  });

  testWidgets('DashboardScreen mostra empty state sem vencimentos próximos',
      (tester) async {
    final repo = FakeLancamentosRepository([
      _lanc(id: 'Antigo', valorCents: 1000, data: DateTime(2020, 1, 1)),
    ]);

    await _pump(tester, repo);

    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Nenhum vencimento próximo.'), findsOneWidget);
    expect(find.text('Sem gastos neste mês.'), findsOneWidget);
  });

  testWidgets('donut mostra legenda por categoria com R\$ e %',
      (tester) async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final repo = FakeLancamentosRepository([
      _lanc(id: 'Pizza', valorCents: 3000, categoria: 'Alimentação', data: mes),
      _lanc(id: 'Ônibus', valorCents: 1000, categoria: 'Transporte', data: mes),
    ]);

    await _pump(tester, repo);

    // Legenda: categoria + valor + %.
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsWidgets);
    expect(find.text('(75%)'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('R\$ 10,00'), findsOneWidget);
    expect(find.text('(25%)'), findsOneWidget);
  });

  testWidgets('seção Metas mostra progresso da meta no dashboard',
      (tester) async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final repo = FakeLancamentosRepository([
      _lanc(id: 'Pizza', valorCents: 9000, categoria: 'Alimentação', data: mes),
    ]);
    final metasRepo = FakeMetasRepository([
      const Meta(id: 'm1', categoria: 'Alimentação', valorLimiteCents: 10000),
    ]);

    await _pump(tester, repo, metasRepo: metasRepo);

    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('R\$ 90,00 de R\$ 100,00'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Gerenciar'), findsOneWidget);
  });

  testWidgets('seção Metas mostra Criar quando não há metas', (tester) async {
    final repo = FakeLancamentosRepository();

    await _pump(tester, repo);

    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Nenhuma meta definida.'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
  });

  testWidgets('seção Patrimônio mostra total e rendimento com link',
      (tester) async {
    final repo = FakeLancamentosRepository();
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.acao,
        nome: 'PETR4',
        quantidade: 10,
        precoAtualCents: 4000,
      ),
    ]);

    await _pump(tester, repo, investimentosRepo: investimentos);

    expect(find.text('Patrimônio'), findsOneWidget);
    expect(find.text('R\$ 400,00'), findsWidgets);
    expect(find.text('Ver'), findsOneWidget);
    // Sem movimentos → custo 0 → rendimento = patrimônio.
    expect(find.text('+R\$ 400,00 rendimento'), findsOneWidget);
  });

  testWidgets('seção Patrimônio não aparece sem ativos', (tester) async {
    await _pump(tester, FakeLancamentosRepository());
    expect(find.text('Patrimônio'), findsNothing);
    expect(find.text('Ver'), findsNothing);
  });
}