import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup_encryption.dart';
import 'backup_snapshot.dart';

const _backupName = 'finance-backup';
const _fileFields = 'id,createdTime,description,sha256Checksum';
const _timeout = Duration(seconds: 30);

class DriveBackup {
  DriveBackup(this.id, this.createdAt, this.description)
    : header = BackupHeader.decode(description);

  final String id;
  final DateTime createdAt;
  final String description;
  final BackupHeader header;
}

abstract interface class BackupDrive {
  Future<List<DriveBackup>> list();
  Future<Uint8List> download(DriveBackup backup);
  Future<DriveBackup> upload(String description, Uint8List encrypted);
  Future<void> delete(DriveBackup backup);
}

class DriveAuthorizationExpired extends BackupProblem {
  const DriveAuthorizationExpired()
    : super('Autorize novamente o acesso à conta Google.');
}

class GoogleBackupDrive implements BackupDrive {
  GoogleBackupDrive(this._accessToken);

  final String _accessToken;
  final _client = HttpClient()..connectionTimeout = _timeout;

  void close() => _client.close(force: true);

  Future<({String id, String email})> account() async {
    final result = await _json('GET', '/drive/v3/about', {
      'fields': 'user(permissionId,emailAddress)',
    });
    final user = result['user'];
    if (user
        case {
          'permissionId': final String id,
          'emailAddress': final String email,
        }
        when id.isNotEmpty && email.isNotEmpty) {
      return (id: id, email: email);
    }
    throw const BackupProblem('Não foi possível confirmar a conta do Drive.');
  }

  @override
  Future<List<DriveBackup>> list() async {
    final files = <String, DriveBackup>{};
    String? pageToken;
    do {
      final result = await _json('GET', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q': "name = '$_backupName'",
        'fields': 'nextPageToken,incompleteSearch,files($_fileFields)',
        'pageSize': '100',
        if (pageToken != null) 'pageToken': pageToken,
      });
      if (result['incompleteSearch'] == true) {
        throw const BackupProblem(
          'O Drive retornou uma lista incompleta. Tente novamente.',
          retry: true,
        );
      }
      final entries = result['files'] as List? ?? const [];
      for (final file in entries.map(_file)) {
        files[file.id] = file;
      }
      pageToken = result['nextPageToken'] as String?;
    } while (pageToken != null);
    return files.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Uint8List> download(DriveBackup backup) => _request(
    'GET',
    '/drive/v3/files/${Uri.encodeComponent(backup.id)}',
    {'alt': 'media'},
    limit: maxBackupBytes,
  );

  @override
  Future<DriveBackup> upload(String description, Uint8List encrypted) async {
    final metadata = jsonEncode({
      'name': _backupName,
      'parents': ['appDataFolder'],
      'description': description,
      'mimeType': 'application/octet-stream',
    });
    Uri? session;
    await _request(
      'POST',
      '/upload/drive/v3/files',
      {'uploadType': 'resumable', 'fields': _fileFields},
      contentType: 'application/json; charset=UTF-8',
      body: utf8.encode(metadata),
      headers: {
        'X-Upload-Content-Type': 'application/octet-stream',
        'X-Upload-Content-Length': '${encrypted.length}',
      },
      onResponse: (headers) =>
          session = Uri.tryParse(headers.value('location') ?? ''),
    );
    final uploadUrl = session;
    if (uploadUrl == null ||
        uploadUrl.scheme != 'https' ||
        !const {
          'www.googleapis.com',
          'content.googleapis.com',
        }.contains(uploadUrl.host) ||
        uploadUrl.userInfo.isNotEmpty ||
        uploadUrl.port != 443) {
      throw const BackupProblem(
        'O Drive não iniciou uma sessão de envio válida.',
      );
    }
    final response = await _request(
      'PUT',
      '',
      {},
      contentType: 'application/octet-stream',
      body: encrypted,
      uploadUrl: uploadUrl,
      timeout: const Duration(minutes: 3),
    );
    final uploaded = jsonDecode(utf8.decode(response)) as Map<String, dynamic>;
    final file = _file(uploaded);
    final hex = await _checksum(encrypted);
    final reported = uploaded['sha256Checksum'] as String?;
    final confirmed =
        reported?.toLowerCase() ?? await _checksum(await download(file));
    if (file.description != description || confirmed != hex) {
      // The previous copy remains intact. Remove our own unverified upload
      // if Drive returned enough information to identify it.
      try {
        await delete(file);
      } on BackupProblem {
        // A subsequent sync will validate the file before importing it.
      }
      throw const BackupProblem(
        'O Drive não confirmou a integridade do envio.',
        retry: true,
      );
    }
    return file;
  }

  @override
  Future<void> delete(DriveBackup backup) async {
    await _request(
      'DELETE',
      '/drive/v3/files/${Uri.encodeComponent(backup.id)}',
      {},
    );
  }

  DriveBackup _file(Object? json) {
    try {
      final file = json as Map<String, dynamic>;
      final id = file['id'] as String;
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
        throw const FormatException();
      }
      return DriveBackup(
        id,
        DateTime.parse(file['createdTime'] as String),
        file['description'] as String,
      );
    } on TypeError {
      throw const BackupProblem(
        'O Drive retornou metadados de backup inválidos.',
      );
    } on FormatException {
      throw const BackupProblem(
        'O Drive retornou metadados de backup inválidos.',
      );
    }
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path,
    Map<String, String> query,
  ) async {
    final raw = await _request(method, path, query);
    return jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
  }

  Future<Uint8List> _request(
    String method,
    String path,
    Map<String, String> query, {
    String? contentType,
    List<int> body = const [],
    Map<String, String> headers = const {},
    Uri? uploadUrl,
    void Function(HttpHeaders)? onResponse,
    int limit = 4 * 1024 * 1024,
    Duration timeout = _timeout,
  }) async {
    Future<Uint8List> send() async {
      final url = uploadUrl ?? Uri.https('www.googleapis.com', path, query);
      final request = await _client.openUrl(method, url);
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $_accessToken',
      );
      headers.forEach(request.headers.set);
      if (contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close();
      final success = response.statusCode >= 200 && response.statusCode < 300;
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (buffer.length + chunk.length > limit) {
          throw const BackupProblem(
            'O arquivo recebido do Drive excede o limite.',
          );
        }
        buffer.add(chunk);
      }
      final bytes = buffer.takeBytes();
      if (!success) throw _driveError(response.statusCode, bytes);
      onResponse?.call(response.headers);
      return bytes;
    }

    try {
      return await send().timeout(
        timeout,
        onTimeout: () {
          close();
          throw const BackupProblem(
            'O Drive demorou a responder. Tente novamente.',
            retry: true,
          );
        },
      );
    } on IOException {
      throw const BackupProblem(
        'Sem conexão com o Google Drive. Confira a internet.',
        retry: true,
      );
    }
  }
}

Future<String> _checksum(Uint8List bytes) async {
  final hash = await Sha256().hash(bytes);
  return hash.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

BackupProblem _driveError(int status, Uint8List bytes) {
  String? reason;
  try {
    final error = jsonDecode(utf8.decode(bytes))['error'];
    reason = (error['errors'] as List).firstOrNull?['reason'] as String?;
  } catch (_) {
    // Some Drive errors have no JSON body.
  }
  if (reason == 'storageQuotaExceeded' || status == 507) {
    return const BackupProblem('A conta Google está sem espaço para o backup.');
  }
  if (reason == 'accessNotConfigured' || reason == 'serviceDisabled') {
    return const BackupProblem(
      'A API do Google Drive precisa ser ativada para este APK.',
    );
  }
  if (status == 429 ||
      status >= 500 ||
      reason == 'rateLimitExceeded' ||
      reason == 'userRateLimitExceeded') {
    return const BackupProblem(
      'O Drive está temporariamente indisponível.',
      retry: true,
    );
  }
  if (status == 401 || status == 403) return const DriveAuthorizationExpired();
  if (status == 404) {
    return const BackupProblem(
      'O backup foi removido do Drive. Atualize a lista.',
    );
  }
  return const BackupProblem('Falha na comunicação com o Google Drive.');
}
