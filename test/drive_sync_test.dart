import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/backup/data/backup_drive.dart';
import 'package:finance_app/features/backup/data/backup_encryption.dart';
import 'package:finance_app/features/backup/data/backup_snapshot.dart';
import 'package:finance_app/features/backup/data/drive_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const account = 'account-a';
  final key = List.filled(32, 7);
  late _FakeDrive drive;
  late BackupDatabase primary;
  late BackupDatabase secondary;
  late DriveSync first;
  late DriveSync second;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    drive = _FakeDrive();
    primary = BackupDatabase(AppDatabase.forTesting(NativeDatabase.memory()));
    secondary = BackupDatabase(AppDatabase.forTesting(NativeDatabase.memory()));
    await primary.initialize(newBackupDevice());
    await secondary.initialize(newBackupDevice());
    first = DriveSync(primary, drive, account, key);
    second = DriveSync(secondary, drive, account, key);
  });

  tearDown(() async {
    await primary.db.close();
    await secondary.db.close();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  Future<void> linkBoth() async {
    await _add(primary, 'Original');
    expect(await first.run(manual: true), SyncOutcome.uploaded);
    final file = (await drive.list()).single;
    expect(await second.restore(await second.prepareRestore(file.id)), isFalse);
  }

  test('new device restores a backup and imports subsequent edits in both directions', () async {
    await linkBoth();
    await _add(primary, 'Do primeiro aparelho');
    expect(await first.run(), SyncOutcome.uploaded);
    expect(await second.run(), SyncOutcome.downloaded);
    await _add(secondary, 'Do segundo aparelho');
    expect(await second.run(), SyncOutcome.uploaded);
    expect(await first.run(), SyncOutcome.downloaded);
    expect(await _names(primary), [
      'Original',
      'Do primeiro aparelho',
      'Do segundo aparelho',
    ]);
    expect(await _names(secondary), await _names(primary));
    expect(await second.run(), SyncOutcome.unchanged);
    expect(await drive.list(), hasLength(3));
  });

  test(
    'concurrent uploads preserve both branches until an explicit choice',
    () async {
      await linkBoth();
      await _add(primary, 'Edição A');
      await _add(secondary, 'Edição B');
      final pending = drive.pauseUpload();
      final uploadA = first.run();
      await pending.started;
      expect(await second.run(), SyncOutcome.uploaded);
      pending.resume();
      expect(await uploadA, SyncOutcome.uploaded);
      final heads = backupHeads(await drive.list());
      expect(heads, hasLength(2));
      expect(await first.run(), SyncOutcome.conflict);
      expect(await second.run(), SyncOutcome.conflict);
      expect(await _names(primary), ['Original', 'Edição A']);
      expect(await _names(secondary), ['Original', 'Edição B']);
      final selected = await first.prepareRestore(heads.first.id);
      expect(await first.restore(selected), isTrue);
      expect(await first.run(), SyncOutcome.uploaded);
      expect(backupHeads(await drive.list()).single.id, isNot(heads.first.id));
      expect(
        await second.run(),
        isIn([SyncOutcome.downloaded, SyncOutcome.unchanged]),
      );
      expect(await _names(secondary), await _names(primary));
      expect(await drive.list(), hasLength(4));
    },
  );

  test(
    'an offline edit is uploaded separately when a newer remote version exists',
    () async {
      await linkBoth();
      await _add(primary, 'Local offline');
      await _add(secondary, 'Remoto');
      await second.run();
      expect(await first.run(), SyncOutcome.conflictUploaded);
      expect(await first.run(), SyncOutcome.conflict);
      expect(backupHeads(await drive.list()), hasLength(2));
      expect(await _names(primary), ['Original', 'Local offline']);
    },
  );

  test('retains ten versions and preserves them when upload fails', () async {
    await linkBoth();
    for (var index = 0; index < retainedBackupCount + 2; index++) {
      await _add(primary, 'Conta $index');
      await first.run();
    }
    final before = await drive.list();
    expect(before, hasLength(retainedBackupCount));
    final baseline = await primary.baseline(account);
    await _add(primary, 'Pendente');
    for (final failure in [
      const BackupProblem('Offline', retry: true),
      const BackupProblem('Sem espaço'),
      const DriveAuthorizationExpired(),
    ]) {
      drive.failure = failure;
      await expectLater(first.run(), throwsA(same(failure)));
      expect(await drive.list(), before);
      final current = await primary.baseline(account);
      expect(current?.clock, baseline?.clock);
      expect(current?.digest, baseline?.digest);
    }
    drive.failure = null;
    expect(await first.run(), SyncOutcome.uploaded);
    expect(await drive.list(), hasLength(retainedBackupCount));
  });

  test(
    'resolves an upload whose response was lost without duplicating data',
    () async {
      await linkBoth();
      await _add(primary, 'Enviado');
      drive.failAfterCommit = true;
      await expectLater(first.run(), throwsA(isA<BackupProblem>()));
      expect(await drive.list(), hasLength(2));
      expect(await first.run(), SyncOutcome.unchanged);
      expect(await second.run(), SyncOutcome.downloaded);
      expect(await _names(secondary), ['Original', 'Enviado']);
      expect(await drive.list(), hasLength(2));
    },
  );

  test('a historical restore recovers from a corrupt current backup', () async {
    await linkBoth();
    final old = (await drive.list()).single;
    await _add(primary, 'Atual');
    await first.run();
    final newest = (await drive.list()).first;
    drive.corrupt(newest);
    await expectLater(second.run(), throwsA(isA<BackupProblem>()));
    expect(await _names(secondary), ['Original']);
    final prepared = await second.prepareRestore(old.id);
    expect(await second.restore(prepared), isTrue);
    drive.failure = const BackupProblem('Interrompido', retry: true);
    await expectLater(second.run(), throwsA(isA<BackupProblem>()));
    expect(await _names(secondary), ['Original']);
    drive.failure = null;
    expect(await second.run(), SyncOutcome.uploaded);
    expect(await first.run(), SyncOutcome.downloaded);
    expect(await _names(primary), ['Original']);
  });

  test(
    'separate accounts list separate backups and require the correct key',
    () async {
      await linkBoth();
      final isolated = _FakeDrive();
      expect(await isolated.list(), isEmpty);
      final wrongPassword = DriveSync(
        primary,
        drive,
        account,
        List.filled(32, 8),
      );
      await expectLater(
        wrongPassword.run(manual: true, verifyKey: true),
        throwsA(isA<BackupProblem>()),
      );
      final otherAccount = DriveSync(
        secondary,
        isolated,
        'account-b',
        List.filled(32, 9),
      );
      await _add(secondary, 'Da outra conta');
      await otherAccount.run(manual: true);
      expect(await drive.list(), hasLength(1));
      final otherFile = (await isolated.list()).single;
      await expectLater(
        DriveSync(
          primary,
          isolated,
          'account-b',
          key,
        ).prepareRestore(otherFile.id),
        throwsA(isA<BackupProblem>()),
      );
      expect(await _names(primary), ['Original']);
    },
  );

  test(
    'changes after preview prevent a restore from replacing newer data',
    () async {
      await linkBoth();
      final original = (await drive.list()).single;
      final prepared = await second.prepareRestore(original.id);
      await _add(primary, 'Versão nova');
      await first.run();
      await expectLater(
        second.restore(prepared),
        throwsA(isA<BackupProblem>()),
      );

      final fresh = await second.prepareRestore(original.id);
      await _add(secondary, 'Edição depois de revisar');
      await expectLater(second.restore(fresh), throwsA(isA<BackupProblem>()));
      expect(await _names(secondary), ['Original', 'Edição depois de revisar']);
    },
  );
}

Future<void> _add(BackupDatabase database, String name) => database.db
    .into(database.db.accounts)
    .insert(AccountsCompanion.insert(name: name, type: 'checking'));

Future<List<String>> _names(BackupDatabase database) async =>
    (await database.db.select(database.db.accounts).get())
        .map((account) => account.name)
        .toList();

class _FakeDrive implements BackupDrive {
  final _files = <DriveBackup, Uint8List>{};
  BackupProblem? failure;
  bool failAfterCommit = false;
  int _nextFile = 0;
  ({Completer<void> start, Completer<void> finish})? _pause;

  ({Future<void> started, void Function() resume}) pauseUpload() {
    final start = Completer<void>();
    final finish = Completer<void>();
    _pause = (start: start, finish: finish);
    return (started: start.future, resume: finish.complete);
  }

  void corrupt(DriveBackup file) => _files[file]![20] ^= 1;

  @override
  Future<List<DriveBackup>> list() async =>
      _files.keys.toList().reversed.toList();

  @override
  Future<Uint8List> download(DriveBackup backup) async => _files[backup]!;

  @override
  Future<DriveBackup> upload(String description, Uint8List encrypted) async {
    final error = failure;
    if (error != null) throw error;
    final pause = _pause;
    _pause = null;
    if (pause != null) {
      pause.start.complete();
      await pause.finish.future;
    }
    final file = DriveBackup(
      'file_${++_nextFile}',
      DateTime.utc(2026, 1, _nextFile),
      description,
    );
    _files[file] = Uint8List.fromList(encrypted);
    if (failAfterCommit) {
      failAfterCommit = false;
      throw const BackupProblem('Resposta perdida', retry: true);
    }
    return file;
  }

  @override
  Future<void> delete(DriveBackup backup) async => _files.remove(backup);
}
