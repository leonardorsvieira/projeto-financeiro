import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/main.dart';

void main() {
  testWidgets('home renders Meu Bolso title and placeholder', (tester) async {
    await tester.pumpWidget(const MeuBolsoApp());

    // AppBar + body title.
    expect(find.text('Meu Bolso'), findsWidgets);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });
}