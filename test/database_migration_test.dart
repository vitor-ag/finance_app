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
      expect(account.initialBalance, 100);
      expect(account.currentBalance, 75);
      expect((await db.select(db.categories).getSingle()).name, 'Mercado');

      final expense = await db.select(db.transactions).getSingle();
      expect(expense.accountId, account.id);
      expect(expense.categoryId, 1);
      expect(expense.amount, 25);
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
    expect(version.read<int>('user_version'), 2);
    expect(
      (await reopenedDb.select(reopenedDb.accounts).getSingle()).currentBalance,
      75,
    );
  });
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
