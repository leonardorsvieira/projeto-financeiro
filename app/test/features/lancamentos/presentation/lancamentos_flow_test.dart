import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/lancamentos/presentation/lancamento_form_screen.dart';
import 'package:meubolso/main.dart';

import '../../../support/fake_wrappers.dart';

Lancamento _armario() {
  return Lancamento(
    id: 'armario',
    descricao: 'Armário',
    valorCents: 150000,
    categoria: 'Moradia',
    formaPagamento: 'Cartão de Crédito',
    data: DateTime(2026, 9, 5),
    createdAt: DateTime.utc(2026, 9, 5),
    updatedAt: DateTime.utc(2026, 9, 5),
  );
}

Lancamento _salario() {
  return Lancamento(
    id: 'salario',
    descricao: 'Salário',
    valorCents: 300000,
    categoria: 'Outros',
    formaPagamento: 'Pix',
    data: DateTime(2026, 9, 5),
    tipo: TipoLancamento.receita,
    createdAt: DateTime.utc(2026, 9, 5),
    updatedAt: DateTime.utc(2026, 9, 5),
  );
}

void main() {
  Future<FakeLancamentosRepository> pumpApp(
    WidgetTester tester, {
    List<Lancamento>? seed,
  }) async {
    final fakeAuth = FakeAuthRepository(
      const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
    );
    final fakeLancamentos = FakeLancamentosRepository(seed);
    await tester.pumpWidget(
      wrapWithFakes(
        fakeAuth: fakeAuth,
        fakeLancamentos: fakeLancamentos,
        child: const MeuBolsoApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Home agora abre na aba "Resumo" (dashboard); navegar para "Lançamentos".
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    return fakeLancamentos;
  }

  testWidgets('T1: lista vazia mostra empty state', (tester) async {
    await pumpApp(tester);

    expect(find.text('Nenhum lançamento ainda'), findsOneWidget);
  });

  testWidgets('T2: lista com itens renderiza descrição e valor BRL',
      (tester) async {
    await pumpApp(tester, seed: [_armario()]);

    expect(find.text('Armário'), findsOneWidget);
    expect(find.text('-R\$ 1.500,00'), findsOneWidget);
    expect(find.text('05/09/2026 · Moradia'), findsOneWidget);
  });

  testWidgets('T3: criar lançamento via formulário reflete na lista',
      (tester) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mercado');
    await tester.enterText(find.byType(TextFormField).at(1), '89,90');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fake.createCount, 1);
    expect(find.text('Nenhum lançamento ainda'), findsNothing);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('-R\$ 89,90'), findsOneWidget);
  });

  testWidgets('T4: validação bloqueia submit sem criar', (tester) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Informe uma descrição.'), findsOneWidget);
    expect(find.text('Informe um valor.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'X');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.textContaining('Valor inválido'), findsOneWidget);
    expect(fake.createCount, 0);
  });

  testWidgets('T5: editar lançamento existente', (tester) async {
    final fake = await pumpApp(tester, seed: [_armario()]);

    await tester.tap(find.text('Armário'));
    await tester.pumpAndSettle();

    expect(find.byType(LancamentoFormScreen), findsOneWidget);
    expect(find.text('Editar lançamento'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Armário novo');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fake.updateCount, 1);
    expect(find.text('Armário novo'), findsOneWidget);
    expect(find.text('Armário'), findsNothing);
  });

  testWidgets('T6: excluir com confirmação remove; cancelar mantém',
      (tester) async {
    final fake = await pumpApp(tester, seed: [_armario()]);

    // Cancelar: mantém.
    await tester.tap(find.byTooltip('Ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(fake.deleteCount, 0);
    expect(find.text('Armário'), findsOneWidget);

    // Confirmar: remove.
    await tester.tap(find.byTooltip('Ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    expect(fake.deleteCount, 1);
    expect(find.text('Armário'), findsNothing);
    expect(find.text('Nenhum lançamento ainda'), findsOneWidget);
  });

  testWidgets('T7: criar receita via formulário persiste tipo', (tester) async {
    final fake = await pumpApp(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    expect(find.text('Despesa fixa mensal'), findsNothing);
    expect(find.text('Vencimento (opcional)'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Salário');
    await tester.enterText(find.byType(TextFormField).at(1), '3000,00');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fake.createCount, 1);
    final item = fake.items.single;
    expect(item.tipo, TipoLancamento.receita);
    expect(item.vencimento, isNull);
    expect(item.fixoMensal, isFalse);
  });

  testWidgets('T8: editar receita mantém toggle e sem fixa', (tester) async {
    final fake = await pumpApp(tester, seed: [_salario()]);

    await tester.tap(find.text('Salário'));
    await tester.pumpAndSettle();

    expect(find.byType(LancamentoFormScreen), findsOneWidget);
    expect(find.text('Despesa fixa mensal'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Salário novo');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(fake.updateCount, 1);
    expect(fake.items.single.tipo, TipoLancamento.receita);
    expect(find.text('Salário novo'), findsOneWidget);
  });

  testWidgets('T9: lista mostra receita com +, verde e badge Receita',
      (tester) async {
    await pumpApp(tester, seed: [_salario(), _armario()]);

    expect(find.text('+R\$ 3.000,00'), findsOneWidget);
    expect(find.text('-R\$ 1.500,00'), findsOneWidget);
    expect(find.text('Receita'), findsOneWidget);

    final salario = tester.widget<Text>(find.text('+R\$ 3.000,00'));
    expect(salario.style?.color, Colors.green.shade700);
  });
}