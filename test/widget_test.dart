import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AccountsScreen renders empty state', (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Minhas Contas'), findsOneWidget);
    expect(find.text('Nenhuma conta cadastrada'), findsOneWidget);
    expect(find.text('Nova Conta'), findsOneWidget);

    await testDb.close();
  });

  testWidgets('AccountsScreen can create a new account and reactively list it',
      (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on "Nova Conta" FAB
    await tester.tap(find.text('Nova Conta'));
    await tester.pumpAndSettle();

    // Verify modal opened
    expect(find.text('Salvar Conta'), findsOneWidget);

    // Enter account name and initial balance
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da Conta (ex: Nubank, Carteira)'),
      'Nubank',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Saldo Inicial (R\$)'),
      '150.50',
    );

    // Tap "Salvar Conta"
    await tester.tap(find.text('Salvar Conta'));
    await tester.pumpAndSettle();

    // Verify reactive update in UI
    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('Conta Digital'), findsOneWidget);
    expect(find.text('R\$ 150,50'), findsNWidgets(2)); // Card balance + Header total

    await testDb.close();
  });
}
