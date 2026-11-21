import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/money.dart';
import 'tables/accounts_table.dart';
import 'tables/bill_reminder_settings_table.dart';
import 'tables/bills_table.dart';
import 'tables/categories_table.dart';
import 'tables/goals_table.dart';
import 'tables/recurrences_table.dart';
import 'tables/transaction_revisions_table.dart';
import 'tables/transactions_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Recurrences,
    Transactions,
    Bills,
    TransactionRevisions,
    Goals,
    BillReminderSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 3) {
        final foreignKeys = (await customSelect(
          'PRAGMA foreign_keys',
        ).getSingle()).read<bool>('foreign_keys');
        if (foreignKeys) await customStatement('PRAGMA foreign_keys = OFF');
        try {
          await transaction(() async {
            await _migrateMoney(migrator, accounts, {
              'initial_balance': accounts.initialBalanceCents,
              'current_balance': accounts.currentBalanceCents,
            });
            if (from == 1) {
              await migrator.createTable(recurrences);
              await migrator.createTable(bills);
            } else {
              await _migrateMoney(migrator, recurrences, {
                'amount': recurrences.amountCents,
              });
              await _migrateMoney(
                migrator,
                bills,
                {'amount': bills.amountCents},
                newColumns: [bills.repeatDay, bills.previousBillId],
              );
            }
            await _migrateMoney(
              migrator,
              transactions,
              {'amount': transactions.amountCents},
              newColumns: [
                transactions.incomeSource,
                if (from == 1) transactions.recurrenceId,
              ],
            );
            await migrator.createTable(transactionRevisions);
            await _createNewTables(migrator, from);
          });
        } finally {
          if (foreignKeys) await customStatement('PRAGMA foreign_keys = ON');
        }
      } else {
        await transaction(() => _createNewTables(migrator, from));
      }
    },
  );

  Future<void> _createNewTables(Migrator migrator, int from) async {
    if (from < 4) await migrator.createTable(goals);
    if (from < 5) await migrator.createTable(billReminderSettings);
  }

  Future<void> _migrateMoney(
    Migrator migrator,
    TableInfo table,
    Map<String, GeneratedColumn<int>> amounts, {
    List<GeneratedColumn> newColumns = const [],
  }) async {
    final name = table.actualTableName;
    final columns = amounts.keys;
    final placeholders = List.filled(columns.length + 1, '?').join(', ');
    await customStatement(
      'CREATE TEMP TABLE legacy_money (id INTEGER PRIMARY KEY, '
      '${columns.map((column) => '$column INTEGER NOT NULL').join(', ')})',
    );

    // Copy in chunks so the upgrade can handle long transaction histories.
    int? lastId;
    while (true) {
      final rows = await customSelect(
        'SELECT id, ${columns.join(', ')} FROM $name '
        '${lastId == null ? '' : 'WHERE id > ? '}ORDER BY id LIMIT 500',
        variables: [if (lastId != null) Variable<int>(lastId)],
      ).get();
      if (rows.isEmpty) break;
      await batch((batch) {
        for (final row in rows) {
          lastId = row.read<int>('id');
          batch.customStatement(
            'INSERT INTO legacy_money VALUES ($placeholders)',
            [
              lastId,
              for (final column in columns)
                _legacyCents(row.data[column], name, lastId!),
            ],
          );
        }
      });
    }

    await migrator.alterTable(
      TableMigration(
        table,
        newColumns: newColumns,
        columnTransformer: {
          for (final entry in amounts.entries)
            entry.value: CustomExpression<int>(
              '(SELECT ${entry.key} FROM legacy_money WHERE legacy_money.id = $name.id)',
            ),
        },
      ),
    );
    await customStatement('DROP TABLE legacy_money');
  }

  static final _legacyDecimal = RegExp(
    r'^(-?)([0-9]+)(?:\.([0-9]+))?(?:e([+-]?[0-9]+))?$',
  );

  int _legacyCents(Object? value, String table, int id) {
    final match = value is num
        ? _legacyDecimal.firstMatch(value.toString())
        : null;
    if (match != null) {
      // Round the decimal representation, not its binary floating-point product.
      final fraction = match[3] ?? '';
      final digits = BigInt.parse(match[2]! + fraction);
      final scale = (int.tryParse(match[4] ?? '') ?? 0) + 2 - fraction.length;
      final factor = BigInt.from(10).pow(scale.abs());
      final cents = scale >= 0
          ? digits * factor
          : (digits + factor ~/ BigInt.from(2)) ~/ factor;
      if (cents <= BigInt.from(maxMoneyCents)) {
        return match[1] == '-' ? -cents.toInt() : cents.toInt();
      }
    }
    throw StateError('Há um valor inválido em $table no registro $id.');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
