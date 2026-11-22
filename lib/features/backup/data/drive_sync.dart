import 'backup_drive.dart';
import 'backup_encryption.dart';
import 'backup_snapshot.dart';

const retainedBackupCount = 10;

enum SyncOutcome { unchanged, uploaded, downloaded, conflict, conflictUploaded }

class PreparedRestore {
  const PreparedRestore._(
    this.file,
    this.snapshot,
    this._localDigest,
    this._heads,
  );

  final DriveBackup file;
  final BackupSnapshot snapshot;
  final String _localDigest;
  final List<DriveBackup> _heads;
}

class DriveSync {
  DriveSync(this.database, this.drive, this.account, this._key);

  final BackupDatabase database;
  final BackupDrive drive;
  final String account;
  final List<int> _key;

  Future<SyncOutcome> run({bool manual = false, bool verifyKey = false}) async {
    final backups = await drive.list();
    final heads = backupHeads(backups);
    final local = await database.capture();
    final digest = await local.digest();
    final baseline = await database.baseline(account);
    final base = baseline?.clock ?? const {};
    final dirty =
        digest != baseline?.digest &&
        (baseline == null ||
            !await local.matchesBeforeInvestments(baseline.digest));

    if (heads.isEmpty) {
      if (baseline != null && !manual) {
        throw const BackupProblem(
          'As cópias foram removidas do Drive. Use Backup agora para criar outra.',
        );
      }
      await _publish(local, digest, base, backups);
      return SyncOutcome.uploaded;
    }

    final single = heads.length == 1 ? heads.single : null;
    if (single != null &&
        _sameClock(single.header.clock, base) &&
        baseline?.digest.isNotEmpty == true) {
      if (verifyKey) await _download(single);
      if (!dirty && !manual) return SyncOutcome.unchanged;
      await _publish(local, digest, base, backups);
      return SyncOutcome.uploaded;
    }

    if (baseline == null && local.isEmpty) {
      throw const BackupProblem(
        'Há backups nesta conta. Escolha um em Restaurar backup.',
      );
    }

    final alreadyObserved = heads.every(
      (head) => includesClock(base, head.header.clock),
    );
    if (baseline?.digest == '' && alreadyObserved) {
      // An explicit restore is waiting to be uploaded. Its clock includes
      // exactly the versions the user saw before confirming the replacement.
      if (verifyKey) await _verifyAny(backups);
      await _publish(local, digest, base, backups);
      return SyncOutcome.uploaded;
    }

    // Authenticate every competing head before it can affect this database or
    // be included in the ancestry of a new snapshot.
    for (final head in heads) {
      final incoming = await _download(head);
      if (single == null) continue;
      if (await incoming.digest() == digest &&
          includesClock(head.header.clock, base)) {
        await database.mark(account, head.header.clock, digest);
        return SyncOutcome.unchanged;
      }
      if (!dirty && includesClock(head.header.clock, base)) {
        final applied = await database.restore(
          snapshot: incoming,
          expectedDigest: digest,
          account: account,
          clock: head.header.clock,
        );
        if (!applied) throw _localChanged;
        return SyncOutcome.downloaded;
      }
    }

    if (alreadyObserved) {
      if (!dirty && !manual) return SyncOutcome.unchanged;
      await _publish(local, digest, base, backups);
      return SyncOutcome.uploaded;
    }

    if (dirty) {
      // Keep a separate version for these edits. Claiming the remote clock
      // here would silently discard changes made on the other device.
      await _publish(local, digest, base, backups);
      return SyncOutcome.conflictUploaded;
    }
    return SyncOutcome.conflict;
  }

  Future<PreparedRestore> prepareRestore(String fileId) async {
    final backups = await drive.list();
    final file = backups.where((file) => file.id == fileId).firstOrNull;
    if (file == null) {
      throw const BackupProblem(
        'O backup foi removido do Drive. Atualize a lista.',
      );
    }
    final snapshot = await _download(file);
    return PreparedRestore._(
      file,
      snapshot,
      await (await database.capture()).digest(),
      backupHeads(backups),
    );
  }

  /// Returns true when the local replacement still needs to be published.
  Future<bool> restore(PreparedRestore selection) async {
    final visible = backupHeads(await drive.list());
    if (visible.length != selection._heads.length ||
        visible.any(
          (backup) =>
              !selection._heads.any((original) => original.id == backup.id),
        )) {
      throw const BackupProblem(
        'Há uma nova versão no Drive. Atualize a lista antes de restaurar.',
      );
    }
    final publish =
        visible.length != 1 || visible.single.id != selection.file.id;
    final clock = mergeClocks(visible.map((backup) => backup.header.clock));
    final applied = await database.restore(
      snapshot: selection.snapshot,
      expectedDigest: selection._localDigest,
      account: account,
      clock: clock,
      publish: publish,
    );
    if (!applied) throw _localChanged;
    return publish;
  }

  Future<BackupSnapshot> _download(DriveBackup file) async {
    if (!database.supportsVersion(file.header.schema)) {
      throw const BackupProblem('A versão do banco do backup é incompatível.');
    }
    final encrypted = await drive.download(file);
    final payload = await decryptBackup(encrypted, file.description, _key);
    return database.decode(payload, file.header.schema);
  }

  Future<void> _verifyAny(List<DriveBackup> backups) async {
    BackupProblem? firstFailure;
    for (final file in backups) {
      try {
        await _download(file);
        return;
      } on BackupProblem catch (error) {
        if (error.retry || error is DriveAuthorizationExpired) rethrow;
        firstFailure ??= error;
      }
    }
    if (firstFailure != null) throw firstFailure;
  }

  Future<void> _publish(
    BackupSnapshot snapshot,
    String digest,
    BackupClock base,
    List<DriveBackup> backups,
  ) async {
    final clock = await database.nextClock(base);
    final header = BackupHeader(
      schema: database.schemaVersion,
      clock: clock,
      createdAt: DateTime.now(),
    );
    final description = header.encode();
    final encrypted = await encryptBackup(snapshot.encode(), description, _key);
    final uploaded = await drive.upload(description, encrypted);
    await database.mark(account, clock, digest);

    // A verified upload can retire old versions in its own history. Every
    // concurrent head stays intact, including heads created after our list.
    final ancestors = backups.where(
      (file) => includesClock(clock, file.header.clock),
    );
    for (final previous in ancestors.skip(retainedBackupCount - 1)) {
      if (previous.id == uploaded.id) continue;
      try {
        await drive.delete(previous);
      } on BackupProblem {
        // Retention is best effort; the new copy has already been verified.
        break;
      }
    }
  }
}

const _localChanged = BackupProblem(
  'Os dados locais mudaram durante a operação. Tente novamente.',
  retry: true,
);

bool _sameClock(BackupClock a, BackupClock b) =>
    a.length == b.length &&
    a.entries.every((entry) => b[entry.key] == entry.value);

List<DriveBackup> backupHeads(List<DriveBackup> backups) => [
  for (final candidate in backups)
    if (!backups.any(
      (other) =>
          includesClock(other.header.clock, candidate.header.clock) &&
          !_sameClock(other.header.clock, candidate.header.clock),
    ))
      candidate,
];
