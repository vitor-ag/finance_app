import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/local_access.dart';

final localAccessProvider = ChangeNotifierProvider<LocalAccess?>((ref) {
  if (kIsWeb || !Platform.isAndroid) return null;
  return LocalAccess(
    store: _SecureAccessStore(),
    biometrics: _AndroidBiometrics(),
  );
});

class _SecureAccessStore implements AccessStore {
  static const _key = 'access_record';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      sharedPreferencesName: 'finance_local_access',
    ),
  );

  @override
  Future<String?> read() async {
    final record = await _storage.read(key: _key);
    final marker = await _configurationMarker();
    if (record == null) {
      if (await marker.exists()) {
        throw StateError('Missing local access record');
      }
    } else {
      await marker.create();
    }
    return record;
  }

  @override
  Future<void> write(String record) async {
    await _storage.write(key: _key, value: record);
    await (await _configurationMarker()).create();
  }

  Future<File> _configurationMarker() async {
    // A deleted or unreadable preferences file must not restart password setup.
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'local_access_configured'));
  }
}

class _AndroidBiometrics implements AppBiometrics {
  static const _channel = MethodChannel('finance_app/security');
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async =>
      (await _auth.getAvailableBiometrics()).contains(BiometricType.strong);

  @override
  Future<BiometricResult> authenticate({required bool enroll}) async {
    final result = await _channel.invokeMethod<String>(
      enroll ? 'enroll' : 'authenticate',
    );
    return BiometricResult.values.byName(result!);
  }

  @override
  Future<void> removeKey() => _channel.invokeMethod<void>('removeKey');
}
