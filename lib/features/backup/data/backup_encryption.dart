import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup_snapshot.dart';

const maxBackupBytes = 64 * 1024 * 1024;
const _format = 1;
const _saltLength = 16;
const _nonceLength = 12;
const _tagLength = 16;
const _envelopeOverhead = _saltLength + _nonceLength + _tagLength;

String newBackupDevice() => List.generate(
  16,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

final _random = Random.secure();

class BackupHeader {
  const BackupHeader({
    required this.schema,
    required this.clock,
    required this.createdAt,
  });

  final int schema;
  final BackupClock clock;
  final DateTime createdAt;

  String encode() => jsonEncode({
    'format': _format,
    'schema': schema,
    'clock': clock,
    'created': createdAt.toUtc().toIso8601String(),
  });

  static BackupHeader decode(String description) {
    try {
      final header = jsonDecode(description) as Map<String, dynamic>;
      if (header['format'] != _format) {
        throw const BackupProblem(
          'O formato do backup é incompatível. Atualize o app.',
        );
      }
      final schema = header['schema'] as int;
      final clock = parseBackupClock(header['clock']);
      if (schema <= 0 || clock.isEmpty) throw const FormatException();
      return BackupHeader(
        schema: schema,
        clock: clock,
        createdAt: DateTime.parse(header['created'] as String),
      );
    } on FormatException {
      throw const BackupProblem('O backup contém metadados inválidos.');
    } on TypeError {
      throw const BackupProblem('O backup contém metadados inválidos.');
    }
  }
}

Future<List<int>> deriveBackupKey(String password, String account) {
  if (password.length < 12 || password.length > 128) {
    throw const BackupProblem(
      'Use uma senha de backup de 12 a 128 caracteres.',
    );
  }
  // Drive's per-user permission ID gives all installations on the account
  // the same, account-specific salt without depending on its email address.
  return Isolate.run(() async {
    final key =
        await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 600000,
          bits: 256,
        ).deriveKeyFromPassword(
          password: password,
          nonce: utf8.encode('finance-drive-backup-v1/$account'),
        );
    return key.extractBytes();
  });
}

Future<Uint8List> encryptBackup(
  List<int> data,
  String description,
  List<int> key,
) {
  if (data.length > maxBackupBytes - _envelopeOverhead) {
    throw const BackupProblem('O backup excede o limite de 64 MB.');
  }
  return Isolate.run(() async {
    final cipher = AesGcm.with256bits();
    final salt = List<int>.generate(_saltLength, (_) => _random.nextInt(256));
    final box = await cipher.encrypt(
      data,
      secretKey: await _fileKey(key, salt),
      aad: utf8.encode(description),
    );
    final encrypted = box.concatenation();
    return Uint8List(_saltLength + encrypted.length)
      ..setRange(0, _saltLength, salt)
      ..setRange(_saltLength, _saltLength + encrypted.length, encrypted);
  });
}

Future<List<int>> decryptBackup(
  Uint8List data,
  String description,
  List<int> key,
) {
  if (data.length < _envelopeOverhead || data.length > maxBackupBytes) {
    throw const BackupProblem('O tamanho do arquivo de backup é inválido.');
  }
  return Isolate.run(() async {
    try {
      final cipher = AesGcm.with256bits();
      return await cipher.decrypt(
        SecretBox.fromConcatenation(
          Uint8List.sublistView(data, _saltLength),
          nonceLength: _nonceLength,
          macLength: _tagLength,
        ),
        secretKey: await _fileKey(
          key,
          Uint8List.sublistView(data, 0, _saltLength),
        ),
        aad: utf8.encode(description),
      );
    } on SecretBoxAuthenticationError {
      throw const BackupProblem(
        'Senha de backup incorreta ou arquivo corrompido.',
      );
    }
  });
}

Future<SecretKey> _fileKey(List<int> key, List<int> salt) =>
    Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(key),
      nonce: salt,
      info: utf8.encode('finance-drive-backup-file-v1'),
    );
