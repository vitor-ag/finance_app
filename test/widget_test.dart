import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:finance_app/features/categories/domain/entities/category.dart';

Future<void> closeTestDatabase(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await db.close();
}

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
    final saveEntry = find.text('Salvar Lançamento');
    await tester.ensureVisible(saveEntry);
    await tester.tap(saveEntry);
    await tester.pumpAndSettle();

    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('-R\$ 50,00'), findsOneWidget);
    await closeTestDatabase(tester, testDb);
  });

  testWidgets('Lançamentos can edit, duplicate, trash and restore an entry', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo Lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor (R\$)'), '20');
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();

    final save = find.text('Salvar Lançamento');
    Future<void> saveForm() async {
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
    }

    Future<void> selectAction(String label) async {
      await tester.tap(find.byTooltip('Ações do lançamento').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await saveForm();
    await selectAction('Editar');
    await tester.enterText(find.widgetWithText(TextField, 'Valor (R\$)'), '25');
    await saveForm();
    await selectAction('Duplicar');
    await saveForm();
    expect(find.text('-R\$ 25,00'), findsNWidgets(2));

    await selectAction('Mover para a lixeira');
    await tester.tap(find.widgetWithText(FilledButton, 'Mover para a lixeira'));
    await tester.pumpAndSettle();
    expect(find.text('-R\$ 25,00'), findsOneWidget);
    expect((await db.select(db.accounts).getSingle()).currentBalance, -25);

    await tester.tap(find.byTooltip('Abrir lixeira'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restaurar lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await tester.pumpAndSettle();
    expect(find.text('Lixeira vazia'), findsOneWidget);
    expect((await db.select(db.accounts).getSingle()).currentBalance, -50);
    await closeTestDatabase(tester, db);
  });

  testWidgets('BillsScreen can create a bill, mark it as paid and update balance',
      (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final accountRepo = AccountRepositoryImpl(testDb);
    await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 300,
        currentBalance: 300,
        createdAt: DateTime.now(),
      ),
    );

    final categoryRepo = CategoryRepositoryImpl(testDb);
    await categoryRepo.createCategory(
      const Category(name: 'Moradia', type: 'expense'),
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

    // Navigate to "A Pagar" tab.
    await tester.tap(find.text('A Pagar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma conta a pagar cadastrada'), findsOneWidget);

    // Open the "Nova Conta" sheet.
    await tester.tap(find.text('Nova Conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome (ex: Aluguel, Internet)'),
      'Aluguel',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '120.00',
    );

    // Select the category.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moradia').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar Conta'));
    await tester.pumpAndSettle();

    // Bill was created with a due date in the future -> pending.
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    // Tap the tile to mark it as paid.
    await tester.tap(find.text('Aluguel'));
    await tester.pumpAndSettle();

    expect(find.text('Marcar como paga'), findsOneWidget);

    // Select the payment account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nubank').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Paga'), findsOneWidget);

    final account = await accountRepo.getAccountById(1);
    expect(account!.currentBalance, 180);

    await testDb.close();
  });

  testWidgets('RecurrencesScreen can create a recurrence and generate the first occurrence immediately',
      (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final accountRepo = AccountRepositoryImpl(testDb);
    await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalance: 0,
        currentBalance: 0,
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

    // Navigate to "Recorrências" tab.
    await tester.tap(find.text('Recorrências'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma recorrência cadastrada'), findsOneWidget);

    // Open the "Nova Recorrência" sheet.
    await tester.tap(find.text('Nova Recorrência'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome (ex: Salário, Aluguel)'),
      'Salário',
    );

    // Switch to "Entrada".
    await tester.tap(find.text('Entrada'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '1000.00',
    );

    // Select the account.
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nubank').last);
    await tester.pumpAndSettle();

    // Start date defaults to today, so the first occurrence is
    // generated right after saving (createRecurrence + generateDueOccurrences).
    final saveRecurrence = find.text('Salvar Recorrência');
    await tester.ensureVisible(saveRecurrence);
    await tester.tap(saveRecurrence);
    await tester.pumpAndSettle();

    expect(find.text('Salário'), findsOneWidget);

    final account = await accountRepo.getAccountById(1);
    expect(account!.currentBalance, 1000);

    // Confirm the generated transaction also shows up in Lançamentos.
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();

    expect(find.text('+R\$ 1000,00'), findsOneWidget);
    await closeTestDatabase(tester, testDb);
  });
}
