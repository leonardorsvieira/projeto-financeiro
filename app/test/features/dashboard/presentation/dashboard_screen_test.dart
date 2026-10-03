import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meubolso/features/dashboard/presentation/dashboard_screen.dart';
import 'package:meubolso/features/investimentos/application/investimentos_providers.dart';
import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/lancamentos/application/lancamentos_providers.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/metas/application/metas_providers.dart';
import 'package:meubolso/features/metas/domain/meta.dart';
import 'package:meubolso/features/open_finance/domain/conta_bancaria_conectada.dart';

import 'package:meubolso/features/ditado/application/ditado_providers.dart';
import 'package:meubolso/theme/app_theme.dart';

import '../../../support/fake_ditado_repository.dart';
import '../../../support/fake_investimentos_repository.dart';
import '../../../support/fake_lancamentos_repository.dart';
import '../../../support/fake_metas_repository.dart';

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
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: DashboardScreen()),
      ),
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
        ditadoRepositoryProvider.overrideWithValue(FakeDitadoRepository()),
      ],
      child: child,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mostra o saldo nas contas dos bancos conectados',
      (tester) async {
    final agora = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'open_finance_contas_v1': jsonEncode([
        ContaBancariaConectada(
          id: 'i1',
          nomeBanco: 'Nubank',
          tipoConta: 'Conta & Cartão',
          corHex: '#8A05BE',
          ultimoSync: DateTime(agora.year, agora.month, agora.day, 9, 30),
          saldoContasCents: 123456,
          faturaCartoesCents: 50000,
        ).toMap(),
        ContaBancariaConectada(
          id: 'i2',
          nomeBanco: 'Inter',
          tipoConta: 'Conta',
          corHex: '#FF7A00',
          ultimoSync: DateTime(agora.year, agora.month, agora.day, 10),
          saldoContasCents: 20000,
        ).toMap(),
      ]),
    });

    await _pump(tester, FakeLancamentosRepository());

    expect(find.text('Saldo nas contas'), findsOneWidget);
    expect(find.text('R\$ 1.434,56'), findsOneWidget); // sem a fatura
    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('R\$ 1.234,56'), findsOneWidget);
    expect(find.text('Inter'), findsOneWidget);
    expect(find.text('Atualizado hoje às 09:30'), findsOneWidget);
  });

  testWidgets('sem banco conectado não mostra o saldo nas contas',
      (tester) async {
    await _pump(tester, FakeLancamentosRepository());
    expect(find.text('Saldo nas contas'), findsNothing);
  });

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
        vencimento: agora,
      ),
    ]);

    await _pump(tester, repo);

    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(find.text('Previsto no mês: R\$ 50,00'), findsOneWidget);
    expect(find.text('R\$ 3.000,00'), findsWidgets); // entradas
    expect(find.text('R\$ 100,00'), findsWidgets); // saídas

    await tester.scrollUntilVisible(find.text('Conta luz'), 100);
    expect(find.text('Conta luz'), findsOneWidget);
  });

  testWidgets('saldo do mês soma resgate e desconta aplicação', (tester) async {
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);

    final repo = FakeLancamentosRepository([
      _lanc(
        id: 'Salário',
        valorCents: 300000,
        data: mes,
        tipo: TipoLancamento.receita,
      ),
      _lanc(id: 'Mercado', valorCents: 10000, data: mes),
      _lanc(
        id: 'Resgate caixinha',
        valorCents: 50000,
        data: mes,
        tipo: TipoLancamento.receita,
        categoria: categoriaMovimentacaoInvestimento,
      ),
      _lanc(
        id: 'Aplicação RDB',
        valorCents: 20000,
        data: mes,
        categoria: categoriaMovimentacaoInvestimento,
      ),
    ]);

    await _pump(tester, repo);

    // 3000 − 100 + 500 − 200 = 3200
    expect(find.text('R\$ 3.200,00'), findsOneWidget);
    expect(find.text('R\$ 3.000,00'), findsWidgets); // receitas sem resgate
    expect(find.text('R\$ 100,00'), findsWidgets); // despesas sem aplicação
    expect(
      find.text('Resgatado de investimentos: +R\$ 500,00'),
      findsOneWidget,
    );
    expect(
      find.text('Aplicado em investimentos: -R\$ 200,00'),
      findsOneWidget,
    );
  });

  testWidgets('sem investimentos no mês não mostra as linhas', (tester) async {
    final agora = DateTime.now();
    final repo = FakeLancamentosRepository([
      _lanc(id: 'Mercado', valorCents: 10000, data: agora),
    ]);

    await _pump(tester, repo);

    expect(find.textContaining('investimentos:'), findsNothing);
  });

  testWidgets('DashboardScreen mostra empty state sem vencimentos próximos',
      (tester) async {
    final repo = FakeLancamentosRepository([
      _lanc(id: 'Antigo', valorCents: 1000, data: DateTime(2020, 1, 1)),
    ]);

    await _pump(tester, repo);

    expect(find.text('Saldo do mês'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sem gastos neste mês.'), 100);
    expect(find.text('Sem gastos neste mês.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nenhum vencimento próximo.'), 100);
    expect(find.text('Nenhum vencimento próximo.'), findsOneWidget);
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
    await tester.scrollUntilVisible(find.text('Alimentação'), 100);
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

    await tester.scrollUntilVisible(find.text('Metas'), 100);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('R\$ 90,00 de R\$ 100,00'), findsOneWidget);
    expect(find.text('90% utilizado. Restam R\$ 10,00 até o fim do mês.'), findsOneWidget);
    expect(find.text('Gerenciar'), findsWidgets);
  });

  testWidgets('seção Metas mostra Criar quando não há metas', (tester) async {
    final repo = FakeLancamentosRepository();

    await _pump(tester, repo);

    await tester.scrollUntilVisible(find.text('Metas'), 100);
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
        valorInvestidoCents: 32000,
      ),
    ]);

    await _pump(tester, repo, investimentosRepo: investimentos);

    await tester.scrollUntilVisible(find.text('Patrimônio'), 100);
    expect(find.text('Patrimônio'), findsOneWidget);
    expect(find.text('R\$ 400,00'), findsWidgets);
    expect(find.text('Ver'), findsOneWidget);
    // Aplicado 320 → vale 400: rendeu 80 (25%).
    expect(find.text('+R\$ 80,00 (25,0%) rendimento'), findsOneWidget);
  });

  testWidgets('Patrimônio sem valor aplicado não mostra rendimento',
      (tester) async {
    final investimentos = FakeInvestimentosRepository([
      const Investimento(
        id: 'i1',
        classe: TipoClasseInvestimento.rendaFixa,
        nome: 'Fundo',
        saldoCents: 40000,
      ),
    ]);
    await _pump(tester, FakeLancamentosRepository(),
        investimentosRepo: investimentos);
    await tester.scrollUntilVisible(find.text('Patrimônio'), 100);
    expect(find.text('R\$ 400,00'), findsWidgets);
    expect(find.textContaining('rendimento'), findsNothing);
  });

  testWidgets('seção Patrimônio mostra estado vazio sem ativos', (tester) async {
    await _pump(tester, FakeLancamentosRepository());
    await tester.scrollUntilVisible(find.text('Patrimônio'), 100);
    expect(find.text('Patrimônio'), findsOneWidget);
    expect(find.text('Nenhum investimento cadastrado.'), findsOneWidget);
    expect(find.text('Gerenciar'), findsWidgets);
  });
}