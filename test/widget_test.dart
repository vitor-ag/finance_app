import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/entities/account.dart';
import 'package:finance_app/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:finance_app/features/credit_cards/data/credit_card_repository.dart';
import 'package:finance_app/features/notifications/presentation/providers/reminder_providers.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:finance_app/features/categories/domain/entities/category.dart';

import 'support/fake_reminder_notifications.dart';

Future<void> closeTestDatabase(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await db.close();
}

Future<void> openSettingsPage(WidgetTester tester, String page) async {
  if (page == 'Metas financeiras') {
    await tester.tap(find.text('Planejar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Metas'));
    await tester.pumpAndSettle();
    return;
  }
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
  final label = switch (page) {
    'Contas' => 'Contas e cartões',
    'Recorrências' || 'Contas a pagar' => 'Recorrências e agendados',
    _ => page,
  };
  final target = find.widgetWithText(ListTile, label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  if (page == 'Contas a pagar') {
    await tester.tap(find.widgetWithText(ChoiceChip, page));
    await tester.pumpAndSettle();
  }
}

void compactViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder money(String value) => find.text(value, findRichText: true);

void main() {
  testWidgets(
    'Notificações saves the preferences, schedules a bill and sends a test',
    (tester) async {
      compactViewport(tester);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final gateway = FakeReminderNotifications()..allowed = false;
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day + 3);
      final billId = await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              name: 'Internet',
              amountCents: 10000,
              dueDate: due,
              billType: 'fixed',
            ),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            reminderNotificationsProvider.overrideWithValue(gateway),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openSettingsPage(tester, 'Notificações');
      expect(gateway.scheduled, isEmpty);
      await tester.tap(find.text('Lembretes de vencimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar preferências'));
      await tester.pumpAndSettle();
      expect(gateway.permissionRequests, 1);
      expect(
        gateway.scheduledTimes.values.single,
        DateTime(due.year, due.month, due.day - 1, 9),
      );
      expect(
        (await db.select(db.billReminderSettings).getSingle()).enabled,
        isTrue,
      );

      await tester.tap(find.text('Enviar notificação de teste'));
      await tester.pumpAndSettle();
      expect(gateway.testNotifications, 1);
      await BillRepositoryImpl(db).cancelBill(billId);
      await tester.pumpAndSettle();
      expect(gateway.scheduled, isEmpty);
      await closeTestDatabase(tester, db);
    },
  );

  testWidgets('Metas supports creating a goal and updating its progress', (
    tester,
  ) async {
    compactViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openSettingsPage(tester, 'Metas financeiras');
    expect(find.text('Nenhuma meta cadastrada.'), findsOneWidget);

    await tester.tap(find.text('Nova meta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da meta'),
      'Viagem',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor-alvo (R\$)'),
      '200,00',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Já reservado (R\$)'),
      '50,00',
    );
    await tester.ensureVisible(find.text('Prazo'));
    await tester.tap(find.text('Prazo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar prazo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar meta'));
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();

    expect(money('R\$ 50,00'), findsOneWidget);
    expect(money('R\$ 200,00'), findsOneWidget);
    await tester.tap(find.text('Viagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar à reserva'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '150,00',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta alcançada'), findsOneWidget);
    expect(money('R\$ 200,00'), findsAtLeastNWidgets(2));
    await closeTestDatabase(tester, db);
  });

  testWidgets('Início shows monthly totals and refreshes after a quick entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final accountId = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
    final now = DateTime.now();
    for (final (type, amount, date) in [
      ('income', 1234, DateTime(now.year, now.month)),
      ('expense', 200, DateTime(now.year, now.month)),
      ('income', 1100, DateTime(now.year, now.month, 0, 23, 59)),
      ('expense', 9999, DateTime(now.year, now.month + 1)),
    ]) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: type,
              amountCents: amount,
              date: date,
              accountId: accountId,
            ),
          );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo total'), findsOneWidget);
    expect(money('+R\$ 12,34'), findsOneWidget);
    expect(money('−R\$ 2,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(money('+R\$ 11,00'), findsOneWidget);
    expect(money('+R\$ 12,34'), findsNothing);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(money('−R\$ 2,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo lançamento').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '2,50',
    );
    await tester.pump();
    final save = find.text('Salvar lançamento');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(money('−R\$ 2,50'), findsOneWidget);
    expect(money('−R\$ 4,50'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final bills = find.text('Ver contas a pagar');
    await tester.scrollUntilVisible(bills, 180);
    await tester.ensureVisible(bills);
    await tester.pumpAndSettle();
    await tester.tap(bills);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma conta a pagar cadastrada'), findsOneWidget);
    await closeTestDatabase(tester, db);
  });

  testWidgets('Início opens the forecast and filters movements by account', (
    tester,
  ) async {
    compactViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final bank = await AccountRepositoryImpl(db).createAccount(
      Account(
        name: 'Banco QA',
        type: 'checking',
        initialBalanceCents: 180000,
        currentBalanceCents: 180000,
        createdAt: DateTime.now(),
      ),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateTime(today.year, today.month, today.day + 1);
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            name: 'Aluguel QA',
            amountCents: 210000,
            dueDate: due,
            billType: 'fixed',
          ),
        );
    final cards = CreditCardRepository(db);
    final card = await cards.createCard(
      name: 'Cartão QA',
      limitCents: 200000,
      closingDay: 1,
      dueDay: 2,
    );
    await cards.createPurchase(
      cardId: card,
      description: 'Compra QA',
      amountCents: 2000,
      count: 1,
      date: DateTime(today.year, today.month),
    );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'income',
            amountCents: 10000,
            date: today,
            accountId: bank,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    final forecast = find.widgetWithText(ActionChip, 'Previsão');
    await tester.ensureVisible(forecast);
    await tester.tap(forecast);
    await tester.pumpAndSettle();
    expect(find.text('Previsão de saldo'), findsOneWidget);
    expect(find.textContaining('Saldo fica negativo'), findsOneWidget);
    expect(find.text('Todas as contas ativas'), findsOneWidget);

    final filter = find.byType(DropdownButtonFormField<int>);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banco QA').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Saldo fica negativo'), findsNothing);
    expect(
      find.text('Nenhuma movimentação prevista no período.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Aluguel QA'), 180);
    expect(find.text('Próximos vencimentos'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Compra QA'), 180);
    expect(find.text('Maiores gastos'), findsOneWidget);
    expect(find.text('Compra QA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeTestDatabase(tester, db);
  });

  testWidgets('AccountsScreen renders empty state', (
    WidgetTester tester,
  ) async {
    compactViewport(tester);
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(testDb)],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    await openSettingsPage(tester, 'Contas');

    expect(find.text('Contas e cartões'), findsOneWidget);
    expect(find.text('Nenhuma conta ativa'), findsOneWidget);
    expect(find.text('Nova conta'), findsOneWidget);

    await closeTestDatabase(tester, testDb);
  });

  testWidgets(
    'AccountsScreen can create a new account and reactively list it',
    (WidgetTester tester) async {
      compactViewport(tester);
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(testDb)],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await openSettingsPage(tester, 'Contas');

      // Tap on "Nova Conta" FAB
      await tester.tap(find.text('Nova conta'));
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
      await tester.ensureVisible(find.text('Salvar Conta'));
      await tester.tap(find.text('Salvar Conta'));
      await tester.pumpAndSettle();

      // Verify reactive update in UI
      expect(find.text('Nubank'), findsOneWidget);
      expect(find.text('Conta digital'), findsOneWidget);
      expect(
        money('R\$ 150,50'),
        findsNWidgets(2),
      ); // Card balance + Header total

      await closeTestDatabase(tester, testDb);
    },
  );

  testWidgets('CategoriesScreen can create a new category and list it', (
    WidgetTester tester,
  ) async {
    compactViewport(tester);
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(testDb)],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    await openSettingsPage(tester, 'Categorias');

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
    await tester.ensureVisible(find.text('Salvar Categoria'));
    await tester.tap(find.text('Salvar Categoria'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Despesa'), findsOneWidget);

    await closeTestDatabase(tester, testDb);
  });

  testWidgets('TransactionsScreen can create a new transaction and list it', (
    WidgetTester tester,
  ) async {
    compactViewport(tester);
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final accountRepo = AccountRepositoryImpl(testDb);
    await accountRepo.createAccount(
      Account(
        name: 'Nubank',
        type: 'digital',
        initialBalanceCents: 10000,
        currentBalanceCents: 10000,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(testDb)],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on "Lançamentos" bottom nav destination
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lançamento registrado'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo lançamento').first);
    await tester.pumpAndSettle();

    // Enter amount
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '50.00',
    );

    // Tap "Salvar Lançamento"
    await tester.pump();
    final saveEntry = find.text('Salvar lançamento');
    await tester.ensureVisible(saveEntry);
    await tester.tap(saveEntry);
    await tester.pumpAndSettle();

    expect(find.textContaining('Nubank'), findsOneWidget);
    expect(money('−R\$ 50,00'), findsAtLeastNWidgets(1));
    await closeTestDatabase(tester, testDb);
  });

  testWidgets('Lançamentos can edit, duplicate, trash and restore an entry', (
    tester,
  ) async {
    compactViewport(tester);
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
    await tester.tap(find.byTooltip('Novo lançamento').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor (R\$)'), '20');

    await tester.pump();
    final save = find.text('Salvar lançamento');
    Future<void> saveForm() async {
      await tester.pump();
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
    await selectAction('Histórico de alterações');
    expect(find.textContaining('Saída · R\$ 20,00'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await selectAction('Duplicar');
    await saveForm();
    expect(money('−R\$ 25,00'), findsAtLeastNWidgets(2));

    await selectAction('Mover para a lixeira');
    await tester.tap(find.widgetWithText(FilledButton, 'Mover para a lixeira'));
    await tester.pumpAndSettle();
    expect(money('−R\$ 25,00'), findsAtLeastNWidgets(1));
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -2500,
    );

    await tester.tap(find.byTooltip('Abrir lixeira'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restaurar lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await tester.pumpAndSettle();
    expect(find.text('Lixeira vazia'), findsOneWidget);
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -5000,
    );
    await closeTestDatabase(tester, db);
  });

  testWidgets(
    'BillsScreen can create a bill, mark it as paid and update balance',
    (WidgetTester tester) async {
      compactViewport(tester);
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      final accountRepo = AccountRepositoryImpl(testDb);
      await accountRepo.createAccount(
        Account(
          name: 'Nubank',
          type: 'digital',
          initialBalanceCents: 30000,
          currentBalanceCents: 30000,
          createdAt: DateTime.now(),
        ),
      );

      final categoryRepo = CategoryRepositoryImpl(testDb);
      await categoryRepo.createCategory(
        const Category(name: 'Moradia', type: 'expense'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(testDb)],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await openSettingsPage(tester, 'Contas a pagar');

      expect(find.text('Nenhuma conta a pagar cadastrada'), findsOneWidget);

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

      await tester.ensureVisible(find.text('Salvar Conta'));
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

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Paga'), findsOneWidget);

      final account = await accountRepo.getAccountById(1);
      expect(account!.currentBalanceCents, 18000);

      await closeTestDatabase(tester, testDb);
    },
  );

  testWidgets('BillsScreen can edit and cancel a pending bill', (tester) async {
    compactViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            name: 'Internet',
            amountCents: 5999,
            dueDate: DateTime.now().add(const Duration(days: 7)),
            billType: 'fixed',
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openSettingsPage(tester, 'Contas a pagar');

    await tester.tap(find.byTooltip('Ações da conta a pagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor (R\$)'),
      '60,01',
    );
    final save = find.text('Salvar Conta');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(money('R\$ 60,01'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações da conta a pagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelada'), findsOneWidget);
    expect(await db.select(db.transactions).get(), isEmpty);
    await closeTestDatabase(tester, db);
  });

  testWidgets(
    'RecurrencesScreen can create a recurrence and generate the first occurrence immediately',
    (WidgetTester tester) async {
      compactViewport(tester);
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      final accountRepo = AccountRepositoryImpl(testDb);
      await accountRepo.createAccount(
        Account(
          name: 'Nubank',
          type: 'digital',
          initialBalanceCents: 0,
          currentBalanceCents: 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(testDb)],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await openSettingsPage(tester, 'Recorrências');

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

      final accountField = find.byType(DropdownButtonFormField<int>).first;
      await tester.ensureVisible(accountField);
      await tester.tap(accountField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nubank').last);
      await tester.pumpAndSettle();

      // Start date defaults to today, so the first occurrence is
      // generated right after saving (createRecurrence + generateDueOccurrences).
      final saveRecurrence = find.text('Salvar Recorrência');
      await tester.ensureVisible(saveRecurrence);
      await tester.tap(saveRecurrence);
      await tester.pumpAndSettle();

      expect(find.text('Salário'), findsAtLeastNWidgets(1));

      final account = await accountRepo.getAccountById(1);
      expect(account!.currentBalanceCents, 100000);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lançamentos'));
      await tester.pumpAndSettle();

      expect(money('+R\$ 1.000,00'), findsAtLeastNWidgets(1));
      await closeTestDatabase(tester, testDb);
    },
  );
}
