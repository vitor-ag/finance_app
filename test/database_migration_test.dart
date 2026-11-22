import 'dart:io';

import 'package:drift/drift.dart'
    show DatabaseSchemaEntity, MigrationStrategy, Value;
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/notifications/data/reminder_settings_store.dart';
import 'package:finance_app/features/notifications/domain/reminder_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upgrades version 8 with existing investment accounts', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_investments_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/legacy.sqlite');
    final previous = _LegacyDatabase(NativeDatabase(file), 8);
    await previous
        .into(previous.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Investimentos antigos',
            type: 'investment',
            currentBalanceCents: const Value(12500),
          ),
        );
    await previous.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      12500,
    );
    expect(await db.select(db.investments).get(), isEmpty);
    expect(await db.select(db.investmentMovements).get(), isEmpty);
  });

  test('upgrades version 6 while preserving existing account data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_cards_migration_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finance_app.sqlite');
    final previous = _LegacyDatabase(NativeDatabase(file), 6);
    await previous
        .into(previous.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Conta',
            type: 'cash',
            currentBalanceCents: const Value(4321),
          ),
        );
    await previous.close();
    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      4321,
    );
    expect(await db.select(db.creditCards).get(), isEmpty);
    expect(await db.select(db.cardPurchases).get(), isEmpty);
    expect(await db.select(db.cardInstallments).get(), isEmpty);
    expect(await db.select(db.cardPayments).get(), isEmpty);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
  test('upgrades a populated version 1 database and reopens it', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_migration_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finance_app.sqlite');

    final db = AppDatabase.forTesting(
      NativeDatabase(file, setup: (raw) => raw.execute(_version1Database)),
    );
    try {
      final account = await db.select(db.accounts).getSingle();
      expect(account.name, 'Carteira');
      expect(account.initialBalanceCents, 10000);
      expect(account.currentBalanceCents, 7500);
      expect((await db.select(db.categories).getSingle()).name, 'Mercado');

      final expense = await db.select(db.transactions).getSingle();
      expect(expense.accountId, account.id);
      expect(expense.categoryId, 1);
      expect(expense.amountCents, 2500);
      expect(expense.description, 'Compra');
      expect(expense.recurrenceId, isNull);
      expect(await db.select(db.bills).get(), isEmpty);
      expect(await db.select(db.recurrences).get(), isEmpty);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    } finally {
      await db.close();
    }

    final reopenedDb = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(reopenedDb.close);
    final version = await reopenedDb
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 9);
    expect(
      (await reopenedDb.select(reopenedDb.accounts).getSingle())
          .currentBalanceCents,
      7500,
    );
  });

  test(
    'migrates fractional balances, payments and schedules from version 2',
    () async {
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (raw) => raw.execute(_version1Database + _version2Changes),
        ),
      );
      addTearDown(db.close);

      final account = await db.select(db.accounts).getSingle();
      expect(account.initialBalanceCents, 10000);
      expect(account.currentBalanceCents, 6495);

      final expense = await db.select(db.transactions).getSingle();
      expect(expense.amountCents, 3505);
      expect(expense.recurrenceId, 1);
      expect(expense.incomeSource, isNull);
      final bill = await db.select(db.bills).getSingle();
      expect(bill.amountCents, 3505);
      expect(bill.status, 'paid');
      expect(bill.paidTransactionId, expense.id);
      expect(bill.repeatDay, isNull);
      expect((await db.select(db.recurrences).getSingle()).amountCents, 101);
      expect(await db.select(db.transactionRevisions).get(), isEmpty);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
    },
  );

  test('adds goals on upgrade from version 3 without modifying balances or entries', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_goals_migration_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finance_app.sqlite');

    final previous = _LegacyDatabase(NativeDatabase(file), 3);
    late int accountId;
    try {
      accountId = await previous
          .into(previous.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Reserva',
              type: 'savings',
              initialBalanceCents: const Value(12345),
              currentBalanceCents: const Value(17346),
            ),
          );
      expect(
        await previous
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'goals'",
            )
            .get(),
        isEmpty,
      );
      await previous
          .into(previous.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'income',
              amountCents: 5001,
              date: DateTime(2026, 11, 20),
              accountId: accountId,
            ),
          );
    } finally {
      await previous.close();
    }

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    expect(await db.select(db.goals).get(), isEmpty);
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            name: 'Viagem',
            targetCents: 40000,
            dueDate: Value(DateTime(2027, 5, 10)),
            accountId: Value(accountId),
          ),
        );
    final goal = await db.select(db.goals).getSingle();
    expect(goal.accountId, accountId);
    expect(goal.savedCents, 0);
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      17346,
    );
    expect((await db.select(db.transactions).getSingle()).amountCents, 5001);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test(
    'adds reminder preferences to version 4 and keeps existing financial data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'finance_reminder_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/finance_app.sqlite');
      final previous = _LegacyDatabase(NativeDatabase(file), 4);
      try {
        await previous
            .into(previous.bills)
            .insert(
              BillsCompanion.insert(
                name: 'Internet',
                amountCents: 12000,
                dueDate: DateTime(2026, 12, 5),
                billType: 'fixed',
              ),
            );
        await previous
            .into(previous.goals)
            .insert(
              GoalsCompanion.insert(
                name: 'Viagem',
                targetCents: 100000,
                dueDate: Value(DateTime(2027, 1, 20)),
                savedCents: const Value(20000),
              ),
            );
      } finally {
        await previous.close();
      }

      final db = AppDatabase.forTesting(NativeDatabase(file));
      final store = ReminderSettingsStore(db);
      try {
        expect((await store.watch().first).enabled, isFalse);
        await store.save(
          const ReminderSettings(
            enabled: true,
            daysBefore: 3,
            minuteOfDay: 8 * 60 + 15,
          ),
        );
        expect((await db.select(db.bills).getSingle()).amountCents, 12000);
        expect((await db.select(db.goals).getSingle()).savedCents, 20000);
      } finally {
        await db.close();
      }

      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(reopened.close);
      final settings = await ReminderSettingsStore(reopened).watch().first;
      expect(settings.enabled, isTrue);
      expect(settings.daysBefore, 3);
      expect(settings.minuteOfDay, 495);
      expect(settings.configuredAt, isNotNull);
    },
  );
}

// Keep older fixtures independent of columns introduced in the current schema.
class _LegacyDatabase extends AppDatabase {
  _LegacyDatabase(super.executor, this.schemaVersion) : super.forTesting();

  @override
  final int schemaVersion;

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => super.allSchemaEntities
      .where(
        (entity) =>
            entity != investments &&
            entity != investmentMovements &&
            entity != investmentMovementsByPosition &&
            (schemaVersion >= 8 ||
                (entity != budgets && entity != goalMovements)) &&
            (schemaVersion >= 7 ||
                !<DatabaseSchemaEntity>[
                  creditCards,
                  cardPurchases,
                  cardPayments,
                  cardInstallments,
                ].contains(entity)) &&
            (schemaVersion >= 5 || entity != billReminderSettings) &&
            (schemaVersion >= 4 || entity != goals),
      )
      .toList();

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      if (schemaVersion >= 8) return;
      await customStatement('ALTER TABLE categories DROP COLUMN position');
      await customStatement('ALTER TABLE transactions DROP COLUMN note');
      await customStatement('ALTER TABLE transactions DROP COLUMN photo');
      await customStatement('ALTER TABLE recurrences DROP COLUMN entry_status');
      await customStatement('ALTER TABLE recurrences DROP COLUMN note');
      await customStatement(
        'ALTER TABLE recurrences DROP COLUMN income_source',
      );
      if (schemaVersion >= 4) {
        await customStatement('DROP TABLE goals');
        await customStatement('''
        CREATE TABLE goals (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_cents INTEGER NOT NULL,
          saved_cents INTEGER NOT NULL DEFAULT 0,
          due_date INTEGER NOT NULL,
          account_id INTEGER REFERENCES accounts(id)
        )
      ''');
      }
    },
  );
}

// Frozen schema from before bills and recurrences were registered in Drift.
const _version1Database = '''
  PRAGMA user_version = 1;
  CREATE TABLE accounts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    initial_balance REAL NOT NULL DEFAULT 0,
    current_balance REAL NOT NULL DEFAULT 0,
    color TEXT,
    icon TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
    notes TEXT
  );
  CREATE TABLE categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    parent_id INTEGER REFERENCES categories (id),
    color TEXT,
    icon TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
  );
  CREATE TABLE transactions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    date INTEGER NOT NULL,
    account_id INTEGER NOT NULL REFERENCES accounts (id),
    destination_account_id INTEGER REFERENCES accounts (id),
    category_id INTEGER REFERENCES categories (id),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'paid',
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
    deleted_at INTEGER
  );
  INSERT INTO accounts (name, type, initial_balance, current_balance)
    VALUES ('Carteira', 'cash', 100, 75);
  INSERT INTO categories (name, type) VALUES ('Mercado', 'expense');
  INSERT INTO transactions (type, amount, date, account_id, category_id, description)
    VALUES ('expense', 25, 1700000000, 1, 1, 'Compra');
''';

const _version2Changes = '''
  PRAGMA user_version = 2;
  CREATE TABLE recurrences (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL,
    account_id INTEGER NOT NULL REFERENCES accounts (id),
    destination_account_id INTEGER REFERENCES accounts (id),
    category_id INTEGER REFERENCES categories (id), description TEXT,
    frequency TEXT NOT NULL, day_of_month INTEGER, weekday INTEGER,
    start_date INTEGER NOT NULL, end_date INTEGER, max_occurrences INTEGER,
    generated_count INTEGER NOT NULL DEFAULT 0, next_occurrence_date INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'active', created_at INTEGER NOT NULL
  );
  ALTER TABLE transactions ADD COLUMN recurrence_id INTEGER REFERENCES recurrences (id);
  CREATE TABLE bills (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL, category_id INTEGER REFERENCES categories (id),
    amount REAL NOT NULL, due_date INTEGER NOT NULL, bill_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_account_id INTEGER REFERENCES accounts (id),
    paid_transaction_id INTEGER, notes TEXT, created_at INTEGER NOT NULL
  );
  INSERT INTO recurrences (name, type, amount, account_id, frequency,
      start_date, next_occurrence_date, created_at)
    VALUES ('Assinatura', 'expense', 1.005, 1, 'monthly', 1700000000, 1700000000, 1700000000);
  UPDATE accounts SET current_balance = 64.94999999999999 WHERE id = 1;
  UPDATE transactions SET amount = 35.05, recurrence_id = 1 WHERE id = 1;
  INSERT INTO bills (name, amount, due_date, bill_type, status, payment_account_id,
      paid_transaction_id, created_at)
    VALUES ('Conta existente', 35.05, 1700000000, 'recurring', 'paid', 1, 1, 1700000000);
  PRAGMA foreign_keys = ON;
''';
