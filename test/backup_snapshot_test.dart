import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/backup/data/backup_encryption.dart';
import 'package:finance_app/features/backup/data/backup_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const account = 'drive-account';
  late AppDatabase db;
  late BackupDatabase backup;
  late BackupClock clock;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backup = BackupDatabase(db);
    await backup.initialize(newBackupDevice());
    clock = await backup.nextClock({});
  });

  tearDown(() async {
    await db.close();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  test('restores every table and publishes changes to Drift streams', () async {
    await _populate(db);
    final original = await backup.capture();
    final encrypted = await encryptBackup(
      original.encode(),
      'description',
      List.filled(32, 1),
    );
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(other.close);
    final target = BackupDatabase(other);
    await target.initialize(newBackupDevice());
    final stream = other.select(other.transactions).watch();
    final observed = expectLater(
      stream.take(2),
      emitsInOrder([isEmpty, hasLength(1)]),
    );
    final decoded = target.decode(
      await decryptBackup(encrypted, 'description', List.filled(32, 1)),
      backup.schemaVersion,
    );
    expect(
      await target.restore(
        snapshot: decoded,
        expectedDigest: await (await target.capture()).digest(),
        account: account,
        clock: clock,
      ),
      isTrue,
    );
    await observed;
    expect((await target.capture()).encode(), original.encode());
    expect((await target.baseline(account))?.clock, clock);
    final inserted = await other
        .into(other.accounts)
        .insert(AccountsCompanion.insert(name: 'Nova', type: 'checking'));
    expect(inserted, 10);
  });

  test(
    'does not erase intervening writes or commit invalid foreign keys',
    () async {
      final empty = await backup.capture();
      await _populate(db);
      final current = await backup.capture();
      expect(
        await backup.restore(
          snapshot: empty,
          expectedDigest: await empty.digest(),
          account: account,
          clock: clock,
        ),
        isFalse,
      );
      final document = jsonDecode(utf8.decode(current.encode())) as List;
      (document.first as Map)['accounts'] = [];
      final broken = backup.decode(
        utf8.encode(jsonEncode(document)),
        backup.schemaVersion,
      );
      await expectLater(
        backup.restore(
          snapshot: broken,
          expectedDigest: await current.digest(),
          account: account,
          clock: clock,
        ),
        throwsA(isA<BackupProblem>()),
      );
      expect((await backup.capture()).encode(), current.encode());
      expect(await backup.baseline(account), isNull);
      expect(
        () => backup.decode(empty.encode(), backup.schemaVersion + 1),
        throwsA(isA<BackupProblem>()),
      );
    },
  );

  test('rejects tampered content, metadata and passwords', () async {
    final key = await deriveBackupKey('uma senha diferente', account);
    final sameKey = await deriveBackupKey('uma senha diferente', account);
    final otherKey = await deriveBackupKey(
      'uma senha diferente',
      'other-account',
    );
    final payload = [1, 2, 3];
    final header = BackupHeader(
      schema: backup.schemaVersion,
      clock: clock,
      createdAt: DateTime.utc(2026),
    ).encode();
    final encrypted = await encryptBackup(payload, header, key);
    expect(await decryptBackup(encrypted, header, sameKey), payload);
    await expectLater(
      decryptBackup(encrypted, header, otherKey),
      throwsA(isA<BackupProblem>()),
    );
    await expectLater(
      decryptBackup(encrypted, '$header ', key),
      throwsA(isA<BackupProblem>()),
    );
    final corrupted = Uint8List.fromList(encrypted)..[12] ^= 1;
    await expectLater(
      decryptBackup(corrupted, header, key),
      throwsA(isA<BackupProblem>()),
    );
    expect(BackupHeader.decode(header).clock, clock);
  });

  test('captures committed SQLite transactions while another connection writes', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance-backup-test-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}test.sqlite');
    AppDatabase open() => AppDatabase.forTesting(
      NativeDatabase(
        file,
        setup: (database) {
          database.execute('PRAGMA busy_timeout = 5000');
          database.execute('PRAGMA journal_mode = WAL');
        },
      ),
    );
    final reader = open();
    final writer = open();
    addTearDown(() async {
      await writer.close();
      await reader.close();
      await directory.delete(recursive: true);
    });
    await reader.customStatement(
      "INSERT INTO accounts(id, name, type) VALUES (1, 'Conta', 'checking')",
    );
    await reader.customStatement(
      "INSERT INTO goals(name, target_cents, due_date) VALUES ('Meta', 500, 1)",
    );
    await writer.customSelect('SELECT 1').getSingle();
    Future<void> update() async {
      for (var value = 1; value <= 20; value++) {
        await writer.transaction(() async {
          await writer.customStatement(
            'UPDATE accounts SET current_balance_cents = ?',
            [value],
          );
          await writer.customStatement('UPDATE goals SET saved_cents = ?', [
            value,
          ]);
        });
      }
    }

    final writes = update();
    try {
      for (var index = 0; index < 10; index++) {
        final snapshot = await BackupDatabase(reader).capture();
        final rows =
            (jsonDecode(utf8.decode(snapshot.encode())) as List).first as Map;
        expect(rows['accounts'][0][4], rows['goals'][0][3]);
      }
    } finally {
      await writes;
    }
  });
}

Future<void> _populate(AppDatabase db) async {
  final statements = [
    "INSERT INTO accounts(id, name, type) VALUES (1, 'Conta', 'checking'), (9, 'Temporária', 'cash')",
    'DELETE FROM accounts WHERE id = 9',
    "INSERT INTO categories(id, name, type) VALUES (1, 'Casa', 'expense')",
    "INSERT INTO recurrences(id, name, type, amount_cents, account_id, frequency, start_date, next_occurrence_date) VALUES (1, 'Aluguel', 'expense', 100, 1, 'monthly', 1, 2)",
    "INSERT INTO transactions(id, type, amount_cents, date, account_id, category_id, recurrence_id, deleted_at) VALUES (1, 'expense', 100, 1, 1, 1, 1, 3)",
    "INSERT INTO transaction_revisions(id, transaction_id, action, snapshot) VALUES (1, 1, 'deleted', '{}')",
    "INSERT INTO bills(id, name, amount_cents, due_date, bill_type, payment_account_id, paid_transaction_id) VALUES (1, 'Conta', 200, 2, 'eventual', 1, 1)",
    "INSERT INTO goals(id, name, target_cents, due_date, account_id) VALUES (1, 'Meta', 500, 2, 1)",
    'INSERT INTO bill_reminder_settings VALUES (1, 1, 2, 300, 5)',
    "INSERT INTO credit_cards VALUES (1, 'Cartão', 10000, 10, 15, 1)",
    "INSERT INTO card_purchases VALUES (1, 1, 'Compra', 100, 1, 1, 1)",
    'INSERT INTO card_payments VALUES (1, 1, 2, 1, 1, 100, 3)',
    'INSERT INTO card_installments VALUES (1, 1, 1, 100, 2, 3, 1)',
  ];
  await db.transaction(() async {
    for (final statement in statements) {
      await db.customStatement(statement);
    }
  });
}
