import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../../data/local/database.dart';

typedef BackupClock = Map<String, int>;

class BackupProblem implements Exception {
  const BackupProblem(this.message, {this.retry = false});

  final String message;
  final bool retry;

  @override
  String toString() => message;
}

class BackupSnapshot {
  BackupSnapshot._(this._rows, this._sequences);

  final Map<String, List<List<Object?>>> _rows;
  final Map<String, int> _sequences;

  bool get isEmpty => _rows.values.every((rows) => rows.isEmpty);

  List<int> encode() => utf8.encode(jsonEncode([_rows, _sequences]));

  Future<String> digest() async =>
      base64UrlEncode((await Sha256().hash(encode())).bytes);
}

typedef BackupBaseline = ({BackupClock clock, String digest});

/// Copies every managed table from one SQLite read transaction. Restoring
/// uses parameterized inserts into the existing schema and one write transaction.
class BackupDatabase {
  BackupDatabase(this.db);

  final AppDatabase db;

  int get schemaVersion => db.schemaVersion;

  Future<void> initialize(String device) async {
    // Local synchronization metadata is independent of the financial schema
    // and intentionally excluded from snapshots and Drift table notifications.
    await db.transaction(() async {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS cloud_backup_installation (
          id INTEGER PRIMARY KEY CHECK(id = 1), device TEXT NOT NULL,
          counter INTEGER NOT NULL
        )
      ''');
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS cloud_backup_baselines (
          account TEXT PRIMARY KEY, clock TEXT NOT NULL, digest TEXT NOT NULL
        )
      ''');
      await db.customStatement(
        'INSERT OR IGNORE INTO cloud_backup_installation VALUES (1, ?, 0)',
        [device],
      );
    });
  }

  Future<BackupBaseline?> baseline(String account) async {
    final row = await db
        .customSelect(
          'SELECT clock, digest FROM cloud_backup_baselines WHERE account = ?',
          variables: [Variable(account)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      clock: parseBackupClock(jsonDecode(row.read<String>('clock'))),
      digest: row.read<String>('digest'),
    );
  }

  Future<void> mark(String account, BackupClock clock, String digest) =>
      db.customStatement(
        'INSERT OR REPLACE INTO cloud_backup_baselines VALUES (?, ?, ?)',
        [account, jsonEncode(clock), digest],
      );

  Future<BackupClock> nextClock(BackupClock base) => db.transaction(() async {
    final row = await db.customSelect('''
      UPDATE cloud_backup_installation SET counter = counter + 1
        WHERE id = 1 RETURNING device, counter
    ''').getSingle();
    return {...base, row.read<String>('device'): row.read<int>('counter')};
  });

  Future<BackupSnapshot> capture() => db.transaction(_capture);

  Future<BackupSnapshot> _capture() async {
    final rows = <String, List<List<Object?>>>{};
    for (final table in db.allTables) {
      final columns = table.$columns.map((column) => column.name).join(', ');
      final order = table.$primaryKey.map((column) => column.name).join(', ');
      final result = await db
          .customSelect(
            'SELECT $columns FROM ${table.actualTableName} ORDER BY $order',
          )
          .get();
      rows[table.actualTableName] = [
        for (final row in result)
          [for (final column in table.$columns) row.data[column.name]],
      ];
    }
    final sequences = await db
        .customSelect('SELECT name, seq FROM sqlite_sequence ORDER BY name')
        .get();
    return BackupSnapshot._(rows, {
      for (final row in sequences)
        if (rows.containsKey(row.read<String>('name')))
          row.read<String>('name'): row.read<int>('seq'),
    });
  }

  BackupSnapshot decode(List<int> data, int version) {
    if (version != schemaVersion) {
      throw const BackupProblem('A versão do banco do backup é incompatível.');
    }
    try {
      final document = jsonDecode(utf8.decode(data)) as List<dynamic>;
      if (document.length != 2) throw const FormatException();
      final encodedRows = document[0] as Map<String, dynamic>;
      final sequences = Map<String, int>.from(document[1] as Map);
      final rows = <String, List<List<Object?>>>{};
      for (final table in db.allTables) {
        final columns = table.$columns;
        final tableRows = (encodedRows[table.actualTableName] as List)
            .cast<List>();
        for (final row in tableRows) {
          if (row.length != columns.length) throw const FormatException();
          for (var index = 0; index < columns.length; index++) {
            final column = columns[index];
            final value = row[index];
            final valid = value == null
                ? column.$nullable
                : switch (column.type) {
                    DriftSqlType.string => value is String,
                    DriftSqlType.bool => value == 0 || value == 1,
                    DriftSqlType.int || DriftSqlType.dateTime => value is int,
                    _ => false,
                  };
            if (!valid) throw const FormatException();
          }
        }
        rows[table.actualTableName] = tableRows;
      }
      if (rows.length != encodedRows.length ||
          sequences.entries.any(
            (entry) => !rows.containsKey(entry.key) || entry.value < 0,
          )) {
        throw const FormatException();
      }
      return BackupSnapshot._(rows, sequences);
    } on FormatException {
      throw const BackupProblem('O arquivo contém dados inválidos.');
    } on TypeError {
      throw const BackupProblem('O arquivo contém dados inválidos.');
    }
  }

  Future<bool> restore({
    required BackupSnapshot snapshot,
    required String expectedDigest,
    required String account,
    required BackupClock clock,
    bool publish = false,
  }) async {
    final digest = await snapshot.digest();
    final restored = await db.transaction(() async {
      // Acquire the SQLite write lock before checking for intervening edits.
      await db.customStatement(
        'UPDATE cloud_backup_installation SET counter = counter WHERE id = 1',
      );
      if (await (await _capture()).digest() != expectedDigest) return false;

      await db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final table in db.allTables.toList().reversed) {
        await db.customStatement('DELETE FROM ${table.actualTableName}');
        await db.customStatement('DELETE FROM sqlite_sequence WHERE name = ?', [
          table.actualTableName,
        ]);
      }
      await db.batch((batch) {
        for (final table in db.allTables) {
          final name = table.actualTableName;
          final columns = table.$columns
              .map((column) => column.name)
              .join(', ');
          final values = List.filled(table.$columns.length, '?').join(', ');
          for (final row in snapshot._rows[name]!) {
            batch.customStatement(
              'INSERT INTO $name ($columns) VALUES ($values)',
              row,
            );
          }
        }
        for (final sequence in snapshot._sequences.entries) {
          batch.customStatement('DELETE FROM sqlite_sequence WHERE name = ?', [
            sequence.key,
          ]);
          batch.customStatement(
            'INSERT INTO sqlite_sequence(name, seq) VALUES (?, ?)',
            [sequence.key, sequence.value],
          );
        }
      });
      if ((await db.customSelect('PRAGMA foreign_key_check').get())
              .isNotEmpty ||
          await (await _capture()).digest() != digest) {
        throw const BackupProblem(
          'A integridade do banco do backup é inválida.',
        );
      }
      await mark(account, clock, publish ? '' : digest);
      return true;
    });
    if (restored) refresh();
    return restored;
  }

  void refresh() => db.notifyUpdates({
    for (final table in db.allTables) TableUpdate.onTable(table),
  });

  Future<int> dataVersion() async =>
      (await db.customSelect('PRAGMA data_version').getSingle()).read<int>(
        'data_version',
      );
}

BackupClock parseBackupClock(Object? value) {
  if (value is! Map<String, dynamic> ||
      value.entries.any(
        (entry) =>
            !RegExp(r'^[a-f0-9]{32}$').hasMatch(entry.key) ||
            entry.value is! int ||
            (entry.value as int) < 1,
      )) {
    throw const FormatException('Invalid backup clock');
  }
  return Map<String, int>.from(value);
}

bool includesClock(BackupClock clock, BackupClock other) =>
    other.entries.every((entry) => (clock[entry.key] ?? 0) >= entry.value);

BackupClock mergeClocks(Iterable<BackupClock> clocks) {
  final base = <String, int>{};
  for (final clock in clocks) {
    for (final entry in clock.entries) {
      if ((base[entry.key] ?? 0) < entry.value) base[entry.key] = entry.value;
    }
  }
  return base;
}
