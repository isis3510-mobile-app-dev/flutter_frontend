import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_frontend/core/services/attachment_id_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAssetStoreService {
  LocalAssetStoreService._({
    AttachmentIdService? attachmentIdService,
    http.Client? client,
  }) : _attachmentIdService = attachmentIdService ?? AttachmentIdService(),
       _client = client ?? http.Client();

  static final LocalAssetStoreService _instance = LocalAssetStoreService._();

  factory LocalAssetStoreService() => _instance;

  static const String _rootFolder = 'app_specific';
  static const String _assetPathPrefix = 'asset_local_path_';
  static const Duration _downloadTimeout = Duration(seconds: 12);

  final AttachmentIdService _attachmentIdService;
  final http.Client _client;

  Future<String> saveBytesIfMissing({
    required Uint8List bytes,
    required String category,
    required String fileName,
    String? stableId,
    List<String> aliases = const [],
  }) async {
    final localFile = await _resolveTargetFile(
      category: category,
      fileName: fileName,
      stableId: stableId,
    );

    if (!await localFile.exists()) {
      await localFile.writeAsBytes(bytes, flush: true);
    }

    final filePath = localFile.path;
    final allKeys = <String>[
      if (stableId != null && stableId.trim().isNotEmpty) stableId.trim(),
      ...aliases.where((entry) => entry.trim().isNotEmpty).map((e) => e.trim()),
    ];
    await _rememberAliases(filePath: filePath, keys: allKeys);

    return filePath;
  }

  Future<String?> getExistingPathByAnyKey(List<String> keys) async {
    for (final key in keys) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty) {
        continue;
      }
      final cachedPath = await _readCachedPath(normalizedKey);
      if (cachedPath != null) {
        return cachedPath;
      }
    }
    return null;
  }

  Future<String?> ensureLocalCopyFromRemote({
    required String remoteUrl,
    required String category,
    required String fileName,
    String? stableId,
    List<String> aliases = const [],
  }) async {
    final normalizedRemoteUrl = remoteUrl.trim();
    if (normalizedRemoteUrl.isEmpty) {
      return null;
    }

    final firebaseStoragePath = _extractFirebaseStoragePath(normalizedRemoteUrl);
    final allKeys = <String>[
      normalizedRemoteUrl,
      if (firebaseStoragePath != null && firebaseStoragePath.isNotEmpty)
        firebaseStoragePath,
      if (stableId != null && stableId.trim().isNotEmpty) stableId.trim(),
      ...aliases.where((entry) => entry.trim().isNotEmpty).map((e) => e.trim()),
    ];

    final existing = await getExistingPathByAnyKey(allKeys);
    if (existing != null) {
      return existing;
    }

    final uri = Uri.tryParse(normalizedRemoteUrl);
    if (uri == null) {
      return null;
    }

    http.Response response;
    try {
      response = await _client.get(uri).timeout(_downloadTimeout);
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on TimeoutException {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    return saveBytesIfMissing(
      bytes: response.bodyBytes,
      category: category,
      fileName: fileName,
      stableId: stableId,
      aliases: <String>[
        normalizedRemoteUrl,
        if (firebaseStoragePath != null && firebaseStoragePath.isNotEmpty)
          firebaseStoragePath,
        ...aliases,
      ],
    );
  }

  Future<File> _resolveTargetFile({
    required String category,
    required String fileName,
    String? stableId,
  }) async {
    final root = await getApplicationSupportDirectory();
    final normalizedCategory = category
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .map(_attachmentIdService.sanitizePathSegment)
        .join('/');
    final assetDirPath = p.join(root.path, _rootFolder, normalizedCategory);
    final assetDir = Directory(assetDirPath);
    if (!await assetDir.exists()) {
      await assetDir.create(recursive: true);
    }

    final safeFileName = _attachmentIdService.sanitizeFileName(fileName);
    final extension = _attachmentIdService.extensionFromName(safeFileName);
    final safeId = _sanitizeStableId(stableId);
    final baseName = safeId.isEmpty
        ? p.basenameWithoutExtension(safeFileName)
        : safeId;
    final finalName = '$baseName.$extension';

    return File(p.join(assetDir.path, finalName));
  }

  Future<void> _rememberAliases({
    required String filePath,
    required List<String> keys,
  }) async {
    if (keys.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      final normalized = key.trim();
      if (normalized.isEmpty) {
        continue;
      }
      await prefs.setString('$_assetPathPrefix$normalized', filePath);
    }
  }

  Future<String?> _readCachedPath(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('$_assetPathPrefix$key');
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    final file = File(path);
    if (await file.exists()) {
      return path;
    }

    await prefs.remove('$_assetPathPrefix$key');
    return null;
  }

  String _sanitizeStableId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String? _extractFirebaseStoragePath(String remoteUrl) {
    final uri = Uri.tryParse(remoteUrl.trim());
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length < 5) {
      return null;
    }

    // Firebase Storage URLs usually look like: /v0/b/<bucket>/o/<encoded-path>
    final objectIndex = segments.indexOf('o');
    if (objectIndex == -1 || objectIndex == segments.length - 1) {
      return null;
    }

    final encodedPath = segments[objectIndex + 1];
    if (encodedPath.trim().isEmpty) {
      return null;
    }

    try {
      return Uri.decodeComponent(encodedPath).trim();
    } catch (_) {
      return null;
    }
  }
}
