import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

final lockDelayOptions = Map<Duration, String>.unmodifiable({
  Duration.zero: 'Imediatamente',
  const Duration(seconds: 30): '30 segundos',
  const Duration(minutes: 1): '1 minuto',
  const Duration(minutes: 5): '5 minutos',
});

const defaultLockDelay = Duration(seconds: 30);

abstract interface class AccessStore {
  Future<String?> read();
  Future<void> write(String record);
}

enum BiometricResult { success, canceled, unavailable, invalidated }

abstract interface class AppBiometrics {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate({required bool enroll});
  Future<void> removeKey();
}

class AccessProblem implements Exception {
  const AccessProblem(this.message);

  final String message;
}

class LocalAccess extends ChangeNotifier {
  LocalAccess({
    required this._store,
    required this._biometrics,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AccessStore _store;
  final AppBiometrics _biometrics;
  final DateTime Function() _now;
  _AccessRecord? _record;
  bool _disposed = false;
  int _foregroundVersion = 0;
  (DateTime, Stopwatch)? _absence;

  bool ready = false;
  bool loadFailed = false;
  bool busy = false;
  bool unlocked = false;
  bool offerBiometrics = false;

  bool get needsPassword => ready && _record == null;
  bool get biometricsEnabled => _record?.biometricsEnabled ?? false;
  Duration get lockDelay => _record?.lockDelay ?? defaultLockDelay;

  Duration get passwordWait {
    final deadline = _record?.retryAt;
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> load() => _run(() async {
    loadFailed = false;
    try {
      final stored = await _store.read();
      _record = stored == null ? null : _AccessRecord.decode(stored);
      ready = true;
    } catch (_) {
      loadFailed = true;
    }
  });

  Future<bool> biometricsAvailable() async {
    try {
      return await _biometrics.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> createPassword(String password) => _run(() async {
    if (!needsPassword) return;
    final foreground = _foregroundVersion;
    await _save(await _newCredential(password));
    if (foreground != _foregroundVersion) return;
    final available = await biometricsAvailable();
    if (foreground != _foregroundVersion) return;
    offerBiometrics = available;
    unlocked = !available;
  });

  void finishSetup() {
    if (!offerBiometrics || busy) return;
    offerBiometrics = false;
    unlocked = true;
    _notify();
  }

  Future<void> unlockWithPassword(String password) => _run(() async {
    if (!ready || needsPassword || unlocked) return;
    final foreground = _foregroundVersion;
    final checked = await _checkPassword(password);
    if (checked.failures > 0) {
      await _save(checked.copyWith(failures: 0));
    }
    unlocked = foreground == _foregroundVersion;
  });

  Future<void> unlockWithBiometrics() => _run(() async {
    if (!biometricsEnabled || unlocked) return;
    final foreground = _foregroundVersion;
    switch (await _biometrics.authenticate(enroll: false)) {
      case BiometricResult.success:
        unlocked = foreground == _foregroundVersion;
      case BiometricResult.canceled:
        break;
      case BiometricResult.unavailable:
        throw const AccessProblem(
          'Biometria indisponível. Use a senha do app.',
        );
      case BiometricResult.invalidated:
        await _save(_record!.copyWith(biometricsEnabled: false));
        throw const AccessProblem(
          'A biometria mudou. Use a senha e reative a biometria em Segurança.',
        );
    }
  });

  Future<void> enableBiometrics({String? currentPassword}) => _run(() async {
    final foreground = _foregroundVersion;
    if (!offerBiometrics) {
      if (!unlocked || currentPassword == null) return;
      final checked = await _checkPassword(currentPassword);
      if (checked.failures > 0) {
        await _save(checked.copyWith(failures: 0));
      }
    }
    if (foreground != _foregroundVersion) return;
    switch (await _biometrics.authenticate(enroll: true)) {
      case BiometricResult.success:
        if (foreground != _foregroundVersion) {
          await _biometrics.removeKey();
          return;
        }
        await _save(_record!.copyWith(biometricsEnabled: true));
        if (offerBiometrics && foreground == _foregroundVersion) {
          offerBiometrics = false;
          unlocked = true;
        }
      case BiometricResult.canceled:
        throw const AccessProblem('A ativação da biometria foi cancelada.');
      case BiometricResult.unavailable:
      case BiometricResult.invalidated:
        throw const AccessProblem(
          'Biometria forte indisponível neste aparelho.',
        );
    }
  });

  Future<void> disableBiometrics() => _run(() async {
    if (!unlocked || !biometricsEnabled) return;
    await _save(_record!.copyWith(biometricsEnabled: false));
    await _biometrics.removeKey();
  });

  Future<void> changePassword(String current, String replacement) =>
      _run(() async {
        if (!unlocked) return;
        final record = await _checkPassword(current);
        final credential = await _newCredential(replacement);
        await _save(
          credential.copyWith(
            lockDelay: record.lockDelay,
            biometricsEnabled: record.biometricsEnabled,
          ),
        );
      });

  Future<void> setLockDelay(Duration delay) => _run(() async {
    if (!unlocked || !lockDelayOptions.containsKey(delay)) return;
    await _save(_record!.copyWith(lockDelay: delay));
  });

  void enteredBackground() {
    if (_absence != null) return;
    _absence = (_now(), Stopwatch()..start());
    _foregroundVersion++;
    offerBiometrics = false;
    if (lockDelay == Duration.zero) lock();
  }

  void resumed() {
    final absence = _absence;
    _absence = null;
    if (absence == null) return;
    final (leftAt, stopwatch) = absence;
    // Wall time covers device sleep. Monotonic time also guards clock rollback.
    if (stopwatch.elapsed >= lockDelay ||
        _now().difference(leftAt) >= lockDelay) {
      lock();
    }
  }

  void lock() {
    unlocked = false;
    _notify();
  }

  Future<_AccessRecord> _checkPassword(String password) async {
    final record = _record!;
    if (passwordWait > Duration.zero) {
      throw const AccessProblem('Aguarde antes de tentar novamente.');
    }
    if (validLength(password)) {
      final derived = await _derive(password, record.salt);
      // Compare every byte, even if an earlier byte differs.
      var difference = 0;
      for (var i = 0; i < derived.length; i++) {
        difference |= derived[i] ^ record.verifier[i];
      }
      if (difference == 0) return record;
    }
    final failures = min(record.failures + 1, 9);
    final delay = failures < 3 ? 0 : min(5 << (failures - 3), 300);
    await _save(
      record.copyWith(
        failures: failures,
        retryAt: delay == 0 ? null : _now().add(Duration(seconds: delay)),
      ),
    );
    throw const AccessProblem('Senha incorreta.');
  }

  static bool validLength(String password) {
    final length = password.runes.length;
    return length >= 8 && length <= 128;
  }

  static Future<_AccessRecord> _newCredential(String password) async {
    if (!validLength(password) || password.trim().isEmpty) {
      throw const AccessProblem('Crie uma senha de 8 a 128 caracteres.');
    }
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    return _AccessRecord(salt: salt, verifier: await _derive(password, salt));
  }

  static Future<List<int>> _derive(String password, List<int> salt) {
    return compute(_deriveVerifier, (password, salt));
  }

  Future<void> _save(_AccessRecord record) async {
    await _store.write(record.encode());
    _record = record;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      await action();
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

Future<List<int>> _deriveVerifier((String, List<int>) input) async {
  final (password, salt) = input;
  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );
  final key = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  return key.extractBytes();
}

class _AccessRecord {
  const _AccessRecord({
    required this.salt,
    required this.verifier,
    this.lockDelay = defaultLockDelay,
    this.biometricsEnabled = false,
    this.failures = 0,
    this.retryAt,
  });

  factory _AccessRecord.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final salt = base64Decode(json['salt'] as String);
    final verifier = base64Decode(json['verifier'] as String);
    final delay = Duration(seconds: json['lockSeconds'] as int);
    final failures = json['failures'] as int;
    final retryAt = json['retryAt'] as int?;
    if (json['version'] != 1 ||
        salt.length != 16 ||
        verifier.length != 32 ||
        !lockDelayOptions.containsKey(delay) ||
        failures < 0 ||
        failures > 9 ||
        ((failures >= 3) != (retryAt != null))) {
      throw const FormatException('Invalid access record');
    }
    return _AccessRecord(
      salt: salt,
      verifier: verifier,
      lockDelay: delay,
      biometricsEnabled: json['biometrics'] as bool,
      failures: failures,
      retryAt: retryAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(retryAt),
    );
  }

  final List<int> salt;
  final List<int> verifier;
  final Duration lockDelay;
  final bool biometricsEnabled;
  final int failures;
  final DateTime? retryAt;

  _AccessRecord copyWith({
    Duration? lockDelay,
    bool? biometricsEnabled,
    int? failures,
    DateTime? retryAt,
  }) => _AccessRecord(
    salt: salt,
    verifier: verifier,
    lockDelay: lockDelay ?? this.lockDelay,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    failures: failures ?? this.failures,
    retryAt: failures == null ? this.retryAt : retryAt,
  );

  String encode() => jsonEncode({
    'version': 1,
    'salt': base64.encode(salt),
    'verifier': base64.encode(verifier),
    'lockSeconds': lockDelay.inSeconds,
    'biometrics': biometricsEnabled,
    'failures': failures,
    'retryAt': retryAt?.millisecondsSinceEpoch,
  });
}
