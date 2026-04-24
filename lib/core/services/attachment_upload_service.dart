import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';
import 'package:flutter_frontend/firebase_options.dart';

import 'attachment_id_service.dart';
import 'auth_service.dart';
import 'local_asset_store_service.dart';
import 'local_database_service.dart';

class AttachmentUploadService {
  AttachmentUploadService._({
    FirebaseStorage? storage,
    AuthService? authService,
    AttachmentIdService? attachmentIdService,
    LocalAssetStoreService? localAssetStoreService,
    LocalDatabaseService? localDatabaseService,
  }) : _storage =
           storage ?? FirebaseStorage.instanceFor(bucket: _defaultBucketUrl),
       _authService = authService ?? AuthService(),
       _attachmentIdService = attachmentIdService ?? AttachmentIdService(),
       _localAssetStore = localAssetStoreService ?? LocalAssetStoreService(),
       _localDb = localDatabaseService ?? LocalDatabaseService();

  static final AttachmentUploadService _instance = AttachmentUploadService._();

  factory AttachmentUploadService() => _instance;

  final FirebaseStorage _storage;
  final AuthService _authService;
  final AttachmentIdService _attachmentIdService;
  final LocalAssetStoreService _localAssetStore;
  final LocalDatabaseService _localDb;
  final Connectivity _connectivity = Connectivity();
  static const Duration _uploadTimeout = Duration(seconds: 30);
  static const Duration _internetProbeTimeout = Duration(seconds: 3);
  static const String _entityTypeAttachmentUpload = 'attachment_upload';
  static const String _actionUpload = 'upload';
  static const String _attachmentUrlMetaPrefix = 'attachment_url_map.';

  static String get _defaultBucketUrl {
    final configuredBucket =
        DefaultFirebaseOptions.currentPlatform.storageBucket?.trim() ?? '';
    if (configuredBucket.isEmpty) {
      throw Exception('Firebase Storage bucket is not configured.');
    }
    if (configuredBucket.startsWith('gs://')) {
      return configuredBucket;
    }
    return 'gs://$configuredBucket';
  }

  Future<UploadedAttachmentModel> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    String? firebaseUid,
  }) async {
    final resolvedUid = firebaseUid?.trim().isNotEmpty == true
        ? firebaseUid!.trim()
        : _authService.currentUser?.uid;

    if (resolvedUid == null || resolvedUid.isEmpty) {
      throw Exception(
        'Could not resolve firebase uid for profile photo upload.',
      );
    }

    debugPrint(
      '[AttachmentUploadService] uploadProfilePhoto uid=$resolvedUid '
      'bucket=${_storage.bucket}',
    );

    final storagePath = _attachmentIdService.buildProfilePhotoPath(
      firebaseUid: resolvedUid,
      originalFileName: fileName,
    );

    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      storagePath: storagePath,
      localCategory: 'profile_photos',
      localStableId: storagePath,
    );
  }

  Future<UploadedAttachmentModel> uploadPetPhoto({
    required Uint8List bytes,
    required String petId,
    required String fileName,
  }) {
    debugPrint(
      '[AttachmentUploadService] uploadPetPhoto petId=${petId.trim()} '
      'bucket=${_storage.bucket}',
    );

    final storagePath = _attachmentIdService.buildPetPhotoPath(
      petId: petId,
      originalFileName: fileName,
    );

    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      storagePath: storagePath,
      localCategory: 'pet_photos/${petId.trim()}',
      localStableId: storagePath,
    );
  }

  Future<UploadedAttachmentModel> uploadPetDocument({
    required Uint8List bytes,
    required String petId,
    required String fileName,
    String category = 'general',
  }) {
    debugPrint(
      '[AttachmentUploadService] uploadPetDocument petId=${petId.trim()} '
      'category=$category bucket=${_storage.bucket}',
    );

    final storagePath = _attachmentIdService.buildPetDocumentPath(
      petId: petId,
      originalFileName: fileName,
      category: category,
    );

    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      storagePath: storagePath,
      localCategory:
          'documents/${_attachmentIdService.sanitizePathSegment(category)}/${petId.trim()}',
      localStableId: storagePath,
    );
  }

  Future<UploadedAttachmentModel> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String storagePath,
    required String localCategory,
    required String localStableId,
  }) async {
    final contentType = _contentTypeForFileName(fileName);
    final sanitizedFileName = _attachmentIdService.sanitizeFileName(fileName);
    String? localFilePath;
    try {
      localFilePath = await _localAssetStore.saveBytesIfMissing(
        bytes: bytes,
        category: localCategory,
        fileName: sanitizedFileName,
        stableId: localStableId,
        aliases: [storagePath],
      );
    } catch (_) {
      // Local cache failures are handled below depending on connectivity.
    }

    try {
      final hasInternet = await _hasInternetAccess();
      if (!hasInternet) {
        if (localFilePath == null || localFilePath.trim().isEmpty) {
          throw Exception(
            'Cannot queue attachment upload because local cache is unavailable.',
          );
        }
        await _enqueuePendingUpload(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localCategory: localCategory,
          localStableId: localStableId,
          localFilePath: localFilePath,
        );
        return UploadedAttachmentModel(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          downloadUrl: '',
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localFilePath: localFilePath,
          isPendingUpload: true,
        );
      }

      final downloadUrl = await _uploadToFirebase(
        bytes: bytes,
        fileName: sanitizedFileName,
        storagePath: storagePath,
        contentType: contentType,
      );
      await _rememberUploadMapping(storagePath: storagePath, downloadUrl: downloadUrl);

      if (localFilePath != null && localFilePath.trim().isNotEmpty) {
        try {
          await _localAssetStore.saveBytesIfMissing(
            bytes: bytes,
            category: localCategory,
            fileName: sanitizedFileName,
            stableId: localStableId,
            aliases: [storagePath, downloadUrl],
          );
        } catch (_) {
          // Local cache failures should not block remote upload success.
        }
      }

      return UploadedAttachmentModel(
        fileName: sanitizedFileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        contentType: contentType,
        sizeBytes: bytes.lengthInBytes,
        localFilePath: localFilePath,
      );
    } on FirebaseException catch (error) {
      final hasInternet = await _hasInternetAccess();
      if (!hasInternet &&
          localFilePath != null &&
          localFilePath.trim().isNotEmpty) {
        await _enqueuePendingUpload(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localCategory: localCategory,
          localStableId: localStableId,
          localFilePath: localFilePath,
        );
        return UploadedAttachmentModel(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          downloadUrl: '',
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localFilePath: localFilePath,
          isPendingUpload: true,
        );
      }
      debugPrint(
        '[AttachmentUploadService] FirebaseException code=${error.code} '
        'message=${error.message} path=$storagePath',
      );
      throw Exception(
        'Firebase Storage error (${error.code}): ${error.message ?? 'Unknown error.'}',
      );
    } on TimeoutException {
      final hasInternet = await _hasInternetAccess();
      if (!hasInternet &&
          localFilePath != null &&
          localFilePath.trim().isNotEmpty) {
        await _enqueuePendingUpload(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localCategory: localCategory,
          localStableId: localStableId,
          localFilePath: localFilePath,
        );
        return UploadedAttachmentModel(
          fileName: sanitizedFileName,
          storagePath: storagePath,
          downloadUrl: '',
          contentType: contentType,
          sizeBytes: bytes.lengthInBytes,
          localFilePath: localFilePath,
          isPendingUpload: true,
        );
      }
      debugPrint(
        '[AttachmentUploadService] timeout path=$storagePath '
        'bucket=${_storage.bucket}',
      );
      throw Exception(
        'Firebase Storage upload timed out after ${_uploadTimeout.inSeconds}s.',
      );
    } catch (error) {
      debugPrint(
        '[AttachmentUploadService] unexpected error path=$storagePath error=$error',
      );
      rethrow;
    }
  }

  Future<void> retryPendingSyncOperations({int limit = 50}) async {
    final operations = await _localDb.getPendingSyncOperations(
      entityType: _entityTypeAttachmentUpload,
      limit: limit,
    );

    for (final operation in operations) {
      try {
        if (operation.action != _actionUpload) {
          await _localDb.markSyncOperationCompleted(operation.id);
          continue;
        }

        final payload = operation.payload ?? const <String, dynamic>{};
        final storagePath = (payload['storagePath'] as String?)?.trim() ?? '';
        final fileName = (payload['fileName'] as String?)?.trim() ?? '';
        final contentType = (payload['contentType'] as String?)?.trim() ?? '';
        final localPath = (payload['localFilePath'] as String?)?.trim() ?? '';
        final localCategory =
            (payload['localCategory'] as String?)?.trim() ?? 'documents/general';
        final localStableId = (payload['localStableId'] as String?)?.trim() ?? '';

        if (storagePath.isEmpty || localPath.isEmpty || fileName.isEmpty) {
          throw Exception('Invalid queued attachment payload.');
        }

        final file = File(localPath);
        if (!await file.exists()) {
          throw Exception(
            'Local attachment file was not found for queued upload: $localPath',
          );
        }

        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception(
            'Local attachment file is empty for queued upload: $localPath',
          );
        }

        final resolvedContentType = contentType.isEmpty
            ? _contentTypeForFileName(fileName)
            : contentType;
        final downloadUrl = await _uploadToFirebase(
          bytes: bytes,
          fileName: fileName,
          storagePath: storagePath,
          contentType: resolvedContentType,
        );
        await _rememberUploadMapping(
          storagePath: storagePath,
          downloadUrl: downloadUrl,
        );
        await _localAssetStore.saveBytesIfMissing(
          bytes: bytes,
          category: localCategory,
          fileName: fileName,
          stableId: localStableId.isEmpty ? storagePath : localStableId,
          aliases: [storagePath, downloadUrl],
        );

        await _localDb.markSyncOperationCompleted(operation.id);
      } catch (error) {
        await _localDb.markSyncOperationFailed(
          operation.id,
          error: error.toString(),
        );
      }
    }
  }

  Future<Map<String, dynamic>> resolvePendingAttachmentsInPayload(
    Map<String, dynamic> payload,
  ) async {
    final documents = payload['attachedDocuments'];
    if (documents is! List) {
      return payload;
    }

    final resolvedPayload = <String, dynamic>{...payload};
    final resolvedDocuments = <Map<String, dynamic>>[];

    for (final item in documents) {
      final document = _asStringDynamicMap(item);
      final resolvedDocument = await _resolvePendingDocument(document);
      resolvedDocuments.add(resolvedDocument);
    }

    resolvedPayload['attachedDocuments'] = resolvedDocuments;
    return resolvedPayload;
  }

  Future<Map<String, dynamic>> _resolvePendingDocument(
    Map<String, dynamic> document,
  ) async {
    final fileUri = (document['fileUri'] as String?)?.trim() ?? '';
    if (_isRemoteHttpUrl(fileUri)) {
      return document;
    }

    final storagePath = (document['storagePath'] as String?)?.trim() ?? '';
    if (storagePath.isEmpty) {
      return document;
    }

    final downloadUrl = await _localDb.getMetaValue(
      _attachmentUrlMetaKey(storagePath),
    );
    if (downloadUrl != null && downloadUrl.trim().isNotEmpty) {
      return <String, dynamic>{...document, 'fileUri': downloadUrl.trim()};
    }

    final localFilePath = (document['localFilePath'] as String?)?.trim() ?? '';
    final fileName = (document['fileName'] as String?)?.trim() ?? '';
    if (localFilePath.isNotEmpty && fileName.isNotEmpty) {
      final hasInternet = await _hasInternetAccess();
      if (hasInternet) {
        final file = File(localFilePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            final contentType =
                (document['contentType'] as String?)?.trim().isNotEmpty == true
                ? (document['contentType'] as String).trim()
                : _contentTypeForFileName(fileName);
            final uploadedUrl = await _uploadToFirebase(
              bytes: bytes,
              fileName: fileName,
              storagePath: storagePath,
              contentType: contentType,
            );
            await _rememberUploadMapping(
              storagePath: storagePath,
              downloadUrl: uploadedUrl,
            );
            return <String, dynamic>{...document, 'fileUri': uploadedUrl};
          }
        }
      }
    }

    throw Exception(
      'Attachment upload still pending for storage path: $storagePath',
    );
  }

  bool _isRemoteHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Future<String> _uploadToFirebase({
    required Uint8List bytes,
    required String fileName,
    required String storagePath,
    required String contentType,
  }) async {
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'originalFileName': fileName},
    );

    final ref = _storage.ref().child(storagePath);

    debugPrint(
      '[AttachmentUploadService] starting upload path=$storagePath '
      'bytes=${bytes.lengthInBytes} contentType=$contentType',
    );

    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask.timeout(_uploadTimeout);

    debugPrint(
      '[AttachmentUploadService] upload complete state=${snapshot.state.name} '
      'fullPath=${snapshot.ref.fullPath}',
    );

    final downloadUrl = await ref.getDownloadURL().timeout(_uploadTimeout);

    debugPrint('[AttachmentUploadService] download URL resolved path=$storagePath');
    return downloadUrl;
  }

  Future<void> _enqueuePendingUpload({
    required String fileName,
    required String storagePath,
    required String contentType,
    required int sizeBytes,
    required String localCategory,
    required String localStableId,
    required String localFilePath,
  }) async {
    await _localDb.enqueueSyncOperation(
      entityType: _entityTypeAttachmentUpload,
      entityId: localStableId,
      action: _actionUpload,
      payload: <String, dynamic>{
        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'localCategory': localCategory,
        'localStableId': localStableId,
        'localFilePath': localFilePath,
      },
    );
  }

  Future<void> _rememberUploadMapping({
    required String storagePath,
    required String downloadUrl,
  }) async {
    if (storagePath.trim().isEmpty || downloadUrl.trim().isEmpty) {
      return;
    }

    await _localDb.setMetaValue(
      key: _attachmentUrlMetaKey(storagePath),
      value: downloadUrl,
    );
  }

  String _attachmentUrlMetaKey(String storagePath) {
    return '$_attachmentUrlMetaPrefix${storagePath.trim()}';
  }

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  Future<bool> _hasInternetAccess() async {
    final connectivityState = await _connectivity.checkConnectivity();
    if (!_hasNetworkInterface(connectivityState)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(_internetProbeTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasNetworkInterface(dynamic state) {
    final states = <ConnectivityResult>[];

    if (state is ConnectivityResult) {
      states.add(state);
    } else if (state is Iterable) {
      states.addAll(state.whereType<ConnectivityResult>());
    }

    if (states.isEmpty) {
      return false;
    }

    return states.any((item) => item != ConnectivityResult.none);
  }

  String _contentTypeForFileName(String fileName) {
    final extension = _attachmentIdService.extensionFromName(fileName);

    switch (extension) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
