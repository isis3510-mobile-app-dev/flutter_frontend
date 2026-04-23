import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';
import 'package:flutter_frontend/firebase_options.dart';

import 'attachment_id_service.dart';
import 'auth_service.dart';
import 'local_asset_store_service.dart';

class AttachmentUploadService {
  AttachmentUploadService._({
    FirebaseStorage? storage,
    AuthService? authService,
    AttachmentIdService? attachmentIdService,
    LocalAssetStoreService? localAssetStoreService,
  }) : _storage =
           storage ?? FirebaseStorage.instanceFor(bucket: _defaultBucketUrl),
       _authService = authService ?? AuthService(),
       _attachmentIdService = attachmentIdService ?? AttachmentIdService(),
       _localAssetStore = localAssetStoreService ?? LocalAssetStoreService();

  static final AttachmentUploadService _instance = AttachmentUploadService._();

  factory AttachmentUploadService() => _instance;

  final FirebaseStorage _storage;
  final AuthService _authService;
  final AttachmentIdService _attachmentIdService;
  final LocalAssetStoreService _localAssetStore;
  static const Duration _uploadTimeout = Duration(seconds: 30);
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
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'originalFileName': sanitizedFileName},
    );

    final ref = _storage.ref().child(storagePath);

    debugPrint(
      '[AttachmentUploadService] starting upload path=$storagePath '
      'bytes=${bytes.lengthInBytes} contentType=$contentType',
    );

    try {
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask.timeout(_uploadTimeout);

      debugPrint(
        '[AttachmentUploadService] upload complete state=${snapshot.state.name} '
        'fullPath=${snapshot.ref.fullPath}',
      );

      final downloadUrl = await ref.getDownloadURL().timeout(_uploadTimeout);

      debugPrint(
        '[AttachmentUploadService] download URL resolved path=$storagePath',
      );

      String? localFilePath;
      try {
        localFilePath = await _localAssetStore.saveBytesIfMissing(
          bytes: bytes,
          category: localCategory,
          fileName: sanitizedFileName,
          stableId: localStableId,
          aliases: [downloadUrl],
        );
      } catch (_) {
        // Local cache failures should not block remote upload success.
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
      debugPrint(
        '[AttachmentUploadService] FirebaseException code=${error.code} '
        'message=${error.message} path=$storagePath',
      );
      throw Exception(
        'Firebase Storage error (${error.code}): ${error.message ?? 'Unknown error.'}',
      );
    } on TimeoutException {
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
