import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(version.read<int>('user_version'), 3);
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
