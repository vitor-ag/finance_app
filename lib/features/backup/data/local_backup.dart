import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/database_provider.dart';
import 'backup_encryption.dart';
import 'backup_snapshot.dart';

final localBackupProvider = Provider(
  (ref) => LocalBackup(BackupDatabase(ref.watch(databaseProvider))),
);

enum LocalBackupFrequency {
  daily('Diário', Duration(days: 1)),
  weekly('Semanal', Duration(days: 7)),
  monthly('A cada 30 dias', Duration(days: 30));

  const LocalBackupFrequency(this.label, this.interval);
  final String label;
  final Duration interval;
}

class LocalBackup {
  LocalBackup(this.database);

  final BackupDatabase database;
  late final _prefs = SharedPreferencesAsync();
  static const _secure = FlutterSecureStorage();
  static const _channel = MethodChannel('finance_app/local_backup');
  static const _keyName = 'finance.local.backup.key';
  bool _running = false;

  Future<DateTime?> lastBackup() async =>
      DateTime.tryParse(await _prefs.getString('localBackupLast') ?? '');

  Future<void> recordBackup() =>
      _prefs.setString('localBackupLast', DateTime.now().toIso8601String());

  Future<LocalBackupFrequency?> frequency() async {
    final saved = await _prefs.getString('localBackupFrequency');
    return LocalBackupFrequency.values
        .where((value) => value.name == saved)
        .firstOrNull;
  }

  static Future<String?> chooseFolder() => Platform.isAndroid
      ? _channel.invokeMethod<String>('chooseFolder')
      : FilePicker.platform.getDirectoryPath(dialogTitle: 'Pasta de backups');

  Future<void> configure(
    LocalBackupFrequency frequency,
    String folder,
    String password,
  ) async {
    final salt = newBackupDevice();
    final key = await _passwordKey(password, salt);
    await _prefs.remove('localBackupFrequency');
    await _secure.write(key: _keyName, value: '$salt:${base64Encode(key)}');
    await _prefs.setString('localBackupFolder', folder);
    await _prefs.setString('localBackupFrequency', frequency.name);
    await _prefs.remove('localBackupNext');
    await _schedule(true);
  }

  Future<void> disable() async {
    await _prefs.remove('localBackupFrequency');
    await _schedule(false);
    await _secure.delete(key: _keyName);
  }

  static Future<void> _schedule(bool enabled) async {
    if (Platform.isAndroid)
      await _channel.invokeMethod<void>('schedule', enabled);
  }

  static Future<void> completeWorker({required bool retry}) =>
      _channel.invokeMethod<void>('complete', retry);

  Future<void> runAutomatic() async {
    if (_running) return;
    _running = true;
    try {
      final cadence = await frequency();
      if (cadence == null) return;
      final next = DateTime.tryParse(
        await _prefs.getString('localBackupNext') ?? '',
      );
      if (next?.isAfter(DateTime.now()) == true) return;
      final folder = await _prefs.getString('localBackupFolder');
      final saved = await _secure.read(key: _keyName);
      if (folder == null || saved == null)
        throw const BackupProblem(
          'Configure a pasta e a senha do backup automático.',
        );
      final [salt, encoded] = saved.split(':');
      final bytes = await _create(base64Decode(encoded), salt);
      final name = fileName();
      if (Platform.isAndroid) {
        await _channel.invokeMethod<void>('write', {
          'folder': folder,
          'name': name,
          'bytes': bytes,
        });
      } else {
        final destination = File(path.join(folder, name));
        final partial = await File('${destination.path}.part')
            .writeAsBytes(bytes, flush: true);
        try {
          await partial.rename(destination.path);
        } finally {
          if (await partial.exists()) await partial.delete();
        }
      }
      await recordBackup();
      final due = DateTime.now().add(cadence.interval);
      await _prefs.setString('localBackupNext', due.toIso8601String());
      await _prefs.remove('localBackupError');
    } catch (_) {
      await _prefs.setString(
        'localBackupError',
        'O backup automático não foi concluído. Confira a pasta escolhida.',
      );
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<String?> automaticError() => _prefs.getString('localBackupError');

  static String fileName() =>
      'finance-${DateFormat('yyyyMMdd-HHmmss-SSS').format(DateTime.now())}.finance';

  Future<Uint8List> create(String password) async {
    final salt = newBackupDevice();
    return _create(await _passwordKey(password, salt), salt);
  }

  Future<Uint8List> _create(List<int> key, String salt) async {
    final header = BackupHeader(
      schema: database.schemaVersion,
      clock: {salt: 1},
      createdAt: DateTime.now(),
    ).encode();
    final snapshot = await database.capture();
    final encrypted = await encryptBackup(snapshot.encode(), header, key);
    return (BytesBuilder(copy: false)
          ..add(utf8.encode('FINANCE-BACKUP-1\n$header\n'))
          ..add(encrypted))
        .takeBytes();
  }

  Future<LocalRestore> prepare(Uint8List bytes, String password) async {
    final first = bytes.indexOf(10);
    final second = first < 0 ? -1 : bytes.indexOf(10, first + 1);
    if (first != 16 ||
        second < 0 ||
        second > 4096 ||
        bytes.length > maxBackupBytes + 4096 ||
        ascii.decode(bytes.sublist(0, first), allowInvalid: true) !=
            'FINANCE-BACKUP-1') {
      throw const BackupProblem(
        'Selecione um arquivo de backup do Finance App.',
      );
    }
    final description = utf8.decode(bytes.sublist(first + 1, second));
    final header = BackupHeader.decode(description);
    if (header.clock.length != 1)
      throw const BackupProblem('O backup contém metadados inválidos.');
    if (!database.supportsVersion(header.schema)) {
      throw const BackupProblem('A versão do banco do backup é incompatível.');
    }
    final existing = await database.capture();
    final data = await decryptBackup(
      Uint8List.sublistView(bytes, second + 1),
      description,
      await _passwordKey(password, header.clock.keys.single),
    );
    final snapshot = database.decode(data, header.schema);
    return LocalRestore(snapshot, await existing.digest(), header.createdAt);
  }

  Future<void> restore(LocalRestore prepared) async {
    final saved = await database.restore(
      snapshot: prepared.snapshot,
      expectedDigest: prepared.digest,
    );
    if (!saved)
      throw const BackupProblem(
        'Os dados mudaram durante a verificação. Abra o backup novamente.',
      );
  }

  static Future<List<int>> _passwordKey(String password, String salt) =>
      deriveBackupKey(password, 'local-file-v1/$salt');
}

class LocalRestore {
  const LocalRestore(this.snapshot, this.digest, this.createdAt);
  final BackupSnapshot snapshot;
  final String digest;
  final DateTime createdAt;
}
