import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers/database_provider.dart';
import 'backup_drive.dart';
import 'backup_encryption.dart';
import 'backup_snapshot.dart';
import 'drive_sync.dart';

final driveBackupProvider = Provider<AndroidDriveBackup?>((ref) {
  if (kIsWeb || !Platform.isAndroid) return null;
  return AndroidDriveBackup(BackupDatabase(ref.watch(databaseProvider)));
});

final driveStatusProvider = FutureProvider<DriveStatus?>((ref) async {
  return ref.watch(driveBackupProvider)?.status();
});

typedef DriveStatus = ({
  String email,
  bool automatic,
  DateTime? lastUpload,
  DateTime? lastSync,
  String? message,
});

class CloudRestore {
  const CloudRestore._(this._account, this._key, this.selection);

  final String _account;
  final List<int> _key;
  final PreparedRestore selection;
}

class AndroidDriveBackup {
  AndroidDriveBackup(this.database);

  final BackupDatabase database;
  static const _channel = MethodChannel('finance_app/google_drive');
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      sharedPreferencesName: 'finance_drive_backup',
    ),
  );
  static const _storageKey = 'drive_backup_config';

  Future<DriveStatus?> status() async => (await _read())?.status;

  Future<void> connect({bool chooseAccount = true}) => _exclusive(() async {
    final previous = await _read();
    final email = chooseAccount
        ? (await _native<String>('pickAccount'))!
        : previous?.email;
    if (email == null) throw _notLinked;
    await _withDrive(email, (drive, id) async {
      if (id == previous?.id) {
        await _save(previous!..email = email);
      } else {
        await _save(_DriveConfig(id, email));
        await _native<void>('schedule', false);
      }
    }, interactive: true);
  });

  Future<void> disconnect() => _exclusive(() async {
    await _store.delete(key: _storageKey);
    await _native<void>('schedule', false);
  });

  Future<List<DriveBackup>> list() => _exclusive(() async {
    final config = await _requireConfig();
    return _withLinkedDrive(config, (drive) => drive.list());
  });

  Future<SyncOutcome> backupNow(String? password) => _exclusive(() async {
    final config = await _requireConfig();
    final key = password == null
        ? config.key
        : await deriveBackupKey(password, config.id);
    if (key == null) {
      throw const BackupProblem('Informe a senha de criptografia do backup.');
    }
    return _sync(config, key, manual: true, verifyKey: password != null);
  });

  Future<void> setAutomatic(bool enabled, {String? password}) =>
      _exclusive(() async {
        final config = await _requireConfig();
        if (enabled) {
          final key = await deriveBackupKey(password!, config.id);
          await _sync(config, key, verifyKey: true);
          config.key = key;
        } else {
          config.key = null;
        }
        await _save(config);
        await _native<void>('schedule', enabled);
      });

  Future<SyncOutcome?> automaticSync() async {
    // Avoid taking the synchronization lock during ordinary offline use.
    if ((await _read())?.key == null) return null;
    return _exclusive(() async {
      final config = await _read();
      final key = config?.key;
      if (config == null || key == null) return null;
      return _sync(config, key);
    });
  }

  Future<CloudRestore> prepareRestore(String fileId, String password) =>
      _exclusive(() async {
        final config = await _requireConfig();
        final key = await deriveBackupKey(password, config.id);
        return _withLinkedDrive(config, (drive) async {
          await database.initialize(newBackupDevice());
          final selection = await DriveSync(
            database,
            drive,
            config.id,
            key,
          ).prepareRestore(fileId);
          return CloudRestore._(config.id, key, selection);
        });
      });

  /// Applies the selected revision and reports any follow-up upload failure
  /// separately, since the local replacement has already committed.
  Future<String> restore(CloudRestore prepared) => _exclusive(() async {
    final config = await _requireConfig();
    if (config.id != prepared._account) {
      throw const BackupProblem(
        'A conta vinculada mudou. Selecione o backup novamente.',
      );
    }
    final result = await _withLinkedDrive(config, (drive) {
      return DriveSync(
        database,
        drive,
        config.id,
        prepared._key,
      ).restore(prepared.selection);
    });
    if (config.key != null) config.key = prepared._key;
    config.lastSync = DateTime.now();
    config.message = 'Backup restaurado neste aparelho.';
    await _save(config);
    if (!result) return config.message!;
    try {
      final outcome = await _sync(config, prepared._key);
      return switch (outcome) {
        SyncOutcome.conflict || SyncOutcome.conflictUploaded => 'Backup restaurado neste aparelho. Há uma versão concorrente no Drive.',
        _ => 'Backup restaurado e sincronizado com o Drive.',
      };
    } on BackupProblem catch (error) {
      config.message = 'Backup restaurado. Envio pendente. ${error.message}';
      await _save(config);
      return config.message!;
    }
  });

  Future<SyncOutcome> _sync(
    _DriveConfig config,
    List<int> key, {
    bool manual = false,
    bool verifyKey = false,
  }) async {
    try {
      final outcome = await _withLinkedDrive(config, (drive) async {
        await database.initialize(newBackupDevice());
        return DriveSync(
          database,
          drive,
          config.id,
          key,
        ).run(manual: manual, verifyKey: verifyKey);
      });
      config.lastSync = DateTime.now();
      config.message = switch (outcome) {
        SyncOutcome.unchanged => 'Dados atualizados.',
        SyncOutcome.uploaded => 'Backup enviado ao Drive.',
        SyncOutcome.downloaded => 'Alterações do Drive importadas.',
        SyncOutcome.conflict || SyncOutcome.conflictUploaded => 'Há versões de aparelhos diferentes. As cópias foram preservadas. Escolha uma em Restaurar backup.',
      };
      if (outcome == SyncOutcome.uploaded ||
          outcome == SyncOutcome.conflictUploaded) {
        config.lastUpload = config.lastSync;
      }
      await _save(config);
      return outcome;
    } on BackupProblem catch (error) {
      config.message = error.message;
      await _save(config);
      rethrow;
    }
  }

  Future<T> _withLinkedDrive<T>(
    _DriveConfig config,
    Future<T> Function(GoogleBackupDrive) action,
  ) {
    return _withDrive(config.email, (drive, id) {
      if (id != config.id) throw const DriveAuthorizationExpired();
      return action(drive);
    });
  }

  Future<T> _withDrive<T>(
    String email,
    Future<T> Function(GoogleBackupDrive, String) action, {
    bool interactive = false,
  }) async {
    final token = await _native<String>('authorize', {
      'email': email,
      'interactive': interactive,
    });
    if (token == null) throw const DriveAuthorizationExpired();
    final drive = GoogleBackupDrive(token);
    try {
      final profile = await drive.account();
      if (profile.email.toLowerCase() != email.toLowerCase()) {
        throw const BackupProblem(
          'A autorização retornou outra conta. Selecione a conta desejada.',
        );
      }
      return await action(drive, profile.id);
    } on DriveAuthorizationExpired {
      await _native<void>('clearToken', token);
      rethrow;
    } finally {
      drive.close();
    }
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (await _native<bool>('acquire') != true) {
      throw const BackupProblem(
        'Já há uma sincronização em andamento. Tente novamente.',
        retry: true,
      );
    }
    try {
      return await action();
    } finally {
      await _native<void>('release');
    }
  }

  Future<_DriveConfig?> _read() async {
    final value = await _store.read(key: _storageKey);
    return value == null ? null : _DriveConfig.decode(value);
  }

  Future<_DriveConfig> _requireConfig() async =>
      await _read() ?? (throw _notLinked);

  Future<void> _save(_DriveConfig config) =>
      _store.write(key: _storageKey, value: config.encode());

  static Future<void> completeWorker({required bool retry}) =>
      _native<void>('workerComplete', retry ? 'retry' : 'done');

  static Future<T?> _native<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'cancelled' => const BackupProblem('Seleção ou autorização cancelada.'),
        'network' => const BackupProblem(
          'Sem conexão. Confira a internet.',
          retry: true,
        ),
        'play_services' => const BackupProblem(
          'O backup precisa do Google Play Services atualizado.',
        ),
        'oauth_config' => const BackupProblem(
          'A credencial OAuth Android precisa ser configurada para este APK.',
        ),
        _ => const DriveAuthorizationExpired(),
      };
    }
  }
}

const _notLinked = BackupProblem(
  'Vincule uma conta Google para usar o backup em nuvem.',
);

class _DriveConfig {
  _DriveConfig(this.id, this.email);

  final String id;
  String email;
  List<int>? key;
  DateTime? lastUpload;
  DateTime? lastSync;
  String? message;

  DriveStatus get status => (
    email: email,
    automatic: key != null,
    lastUpload: lastUpload,
    lastSync: lastSync,
    message: message,
  );

  String encode() => jsonEncode({
    'id': id,
    'email': email,
    'key': key == null ? null : base64Encode(key!),
    'lastUpload': lastUpload?.toIso8601String(),
    'lastSync': lastSync?.toIso8601String(),
    'message': message,
  });

  static _DriveConfig decode(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    final key = data['key'] as String?;
    final upload = data['lastUpload'] as String?;
    final sync = data['lastSync'] as String?;
    return _DriveConfig(data['id'] as String, data['email'] as String)
      ..key = key == null ? null : base64Decode(key)
      ..lastUpload = upload == null ? null : DateTime.tryParse(upload)
      ..lastSync = sync == null ? null : DateTime.tryParse(sync)
      ..message = data['message'] as String?;
  }
}
