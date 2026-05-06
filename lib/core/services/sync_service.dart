import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';

import 'backup_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // ── Estado público ──────────────────────────────────────────────────────────

  GoogleSignInAccount? _account;
  GoogleSignInAccount? get account => _account;
  bool get isConnected => _account != null;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  /// Chamado após dados remotos serem importados; setado pelo MainScaffold.
  VoidCallback? onDataImported;

  // ── Internos ────────────────────────────────────────────────────────────────

  Timer? _debounceTimer;
  String? _driveFileId;
  static const _driveFileName = 'gerencia_van_backup.json';

  // Arquivo local que persiste o timestamp da última versão conhecida dos dados.
  Future<File> get _lastModFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/gv_last_modified.txt');
  }

  Future<DateTime> _readLastModified() async {
    try {
      final f = await _lastModFile;
      if (!await f.exists()) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse((await f.readAsString()).trim());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> _writeLastModified(DateTime dt) async {
    try {
      final f = await _lastModFile;
      await f.writeAsString(dt.toIso8601String());
    } catch (_) {}
  }

  // ── API pública ─────────────────────────────────────────────────────────────

  /// Chamado no startup: tenta login silencioso e sincroniza.
  Future<void> init() async {
    try {
      _account = await _googleSignIn.signInSilently();
      notifyListeners();
      if (_account != null) await syncNow();
    } catch (_) {
      // Falha silenciosa no startup
    }
  }

  Future<void> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      _lastError = null;
      notifyListeners();
      if (_account != null) await syncNow();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _debounceTimer?.cancel();
    await _googleSignIn.signOut();
    _account = null;
    _driveFileId = null;
    _status = SyncStatus.idle;
    notifyListeners();
  }

  /// Agenda sincronização com debounce de 5 s após uma mutação de dados.
  void scheduleSync() {
    if (!isConnected) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), syncNow);
    // Grava o timestamp de modificação imediatamente (fire-and-forget)
    _writeLastModified(DateTime.now());
  }

  /// Executa a sincronização agora (cancela qualquer debounce pendente).
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    if (!isConnected || _status == SyncStatus.syncing) return;

    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception('Não foi possível autenticar no Google.');
      }

      final driveApi = drive.DriveApi(httpClient);

      final localLastMod = await _readLastModified();
      final localData =
          await BackupService.instance.buildBackupData(asOf: localLastMod);

      final fileId = await _findDriveFileId(driveApi);

      if (fileId == null) {
        // Sem arquivo no Drive: faz upload inicial
        await _upload(driveApi, null, localData);
      } else {
        final remoteContent = await _downloadContent(driveApi, fileId);

        if (remoteContent == null) {
          await _upload(driveApi, fileId, localData);
        } else {
          Map<String, dynamic> remoteData;
          try {
            remoteData = jsonDecode(remoteContent) as Map<String, dynamic>;
          } catch (_) {
            // Arquivo remoto corrompido: sobrescreve
            await _upload(driveApi, fileId, localData);
            _status = SyncStatus.success;
            _lastSync = DateTime.now();
            return;
          }

          final remoteTimeStr = remoteData['exportadoEm'] as String?;
          if (remoteTimeStr == null) {
            await _upload(driveApi, fileId, localData);
          } else {
            final remoteTime = DateTime.parse(remoteTimeStr);

            if (localLastMod.isAfter(remoteTime)) {
              // Local mais recente: envia para o Drive
              await _upload(driveApi, fileId, localData);
            } else if (remoteTime.isAfter(localLastMod)) {
              // Drive mais recente: importa e notifica providers
              final erro = await BackupService.instance.importarDados(remoteData);
              if (erro == null) {
                await _writeLastModified(remoteTime);
                onDataImported?.call();
              }
            }
            // Iguais: nada a fazer
          }
        }
      }

      _status = SyncStatus.success;
      _lastSync = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // ── Helpers Drive ────────────────────────────────────────────────────────────

  Future<String?> _findDriveFileId(drive.DriveApi api) async {
    if (_driveFileId != null) return _driveFileId;
    try {
      final list = await api.files.list(
        q: "name = '$_driveFileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id)',
      );
      final files = list.files;
      if (files != null && files.isNotEmpty) {
        _driveFileId = files.first.id;
        return _driveFileId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadContent(drive.DriveApi api, String fileId) async {
    try {
      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _upload(
    drive.DriveApi api,
    String? existingFileId,
    Map<String, dynamic> data,
  ) async {
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    if (existingFileId == null) {
      final created = await api.files.create(
        drive.File()..name = _driveFileName,
        uploadMedia: media,
      );
      _driveFileId = created.id;
    } else {
      await api.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
      );
    }

    // Atualiza timestamp local para evitar re-upload desnecessário
    final exportedAt = DateTime.parse(data['exportadoEm'] as String);
    await _writeLastModified(exportedAt);
  }
}
