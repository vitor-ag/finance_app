import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';
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

  testWidgets('CategoriesScreen can create a new category and list it',
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

    // Tap on "Categorias" bottom nav destination
    await tester.tap(find.text('Categorias'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma categoria cadastrada'), findsOneWidget);

    // Tap "Nova Categoria" FAB
    await tester.tap(find.text('Nova Categoria'));
    await tester.pumpAndSettle();

    // Enter category name
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da Categoria (ex: Alimentação)'),
      'Alimentação',
    );

    // Tap "Salvar Categoria"
    await tester.tap(find.text('Salvar Categoria'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Despesa'), findsOneWidget);

    await testDb.close();
  });

  testWidgets('TransactionsScreen can create a new transaction and list it',
      (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final accountRepo = AccountRepositoryImpl(testDb);
    await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 100,
        currentBalance: 100,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on "Lançamentos" bottom nav destination
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lançamento registrado'), findsOneWidget);

    // Tap "Novo Lançamento" FAB
    await tester.tap(find.text('Novo Lançamento'));
    await tester.pumpAndSettle();

    // Enter amount
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '50.00',
    );

    // Tap dropdown for Account and select Nubank
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nubank').last);
    await tester.pumpAndSettle();

    // Tap "Salvar Lançamento"
    await tester.tap(find.text('Salvar Lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('-R\$ 50,00'), findsOneWidget);

    await testDb.close();
  });
}
