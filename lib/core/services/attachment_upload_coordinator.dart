import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';

import 'attachment_preprocessing_service.dart';
import 'attachment_upload_service.dart';

class AttachmentUploadCoordinator extends ChangeNotifier {
  AttachmentUploadCoordinator({
    AttachmentUploadService? uploadService,
    AttachmentPreprocessingService? preprocessingService,
  }) : _uploadService = uploadService ?? AttachmentUploadService(),
       _preprocessingService =
           preprocessingService ?? const AttachmentPreprocessingService();

  final AttachmentUploadService _uploadService;
  final AttachmentPreprocessingService _preprocessingService;
  final List<AttachmentUploadItem> _items = <AttachmentUploadItem>[];
  final Map<String, _QueuedAttachmentUpload> _queuedUploads =
      <String, _QueuedAttachmentUpload>{};

  bool _isProcessing = false;

  List<AttachmentUploadItem> get items => List.unmodifiable(_items);

  bool get hasPendingUploads => _items.any((item) => item.isPending);

  bool get hasFailedUploads => _items.any((item) => item.isFailed);

  bool get canSubmit => !hasPendingUploads && !hasFailedUploads;

  void initializeFromExisting(List<EditableAttachmentModel> attachments) {
    _items
      ..clear()
      ..addAll(attachments.map(AttachmentUploadItem.fromExisting));
    _queuedUploads.clear();
    notifyListeners();
  }

  Future<void> enqueueUploads({
    required String petId,
    required List<PendingAttachmentUpload> uploads,
  }) async {
    for (final upload in uploads) {
      _queuedUploads[upload.localId] = _QueuedAttachmentUpload(
        petId: petId,
        upload: upload,
      );
      _items.add(
        AttachmentUploadItem(
          localId: upload.localId,
          fileName: upload.fileName,
          status: AttachmentUploadStatus.queued,
        ),
      );
    }

    notifyListeners();
    await _processQueue();
  }

  Future<void> retry(String localId) async {
    final queuedUpload = _queuedUploads[localId];
    if (queuedUpload == null) {
      return;
    }

    final index = _indexOfLocalId(localId);
    if (index == -1) {
      return;
    }

    _items[index] = _items[index].copyWith(
      status: AttachmentUploadStatus.queued,
      clearErrorMessage: true,
      clearAttachment: true,
    );
    notifyListeners();
    await _processQueue();
  }

  void remove(String localId) {
    _queuedUploads.remove(localId);
    _items.removeWhere((item) => item.localId == localId);
    notifyListeners();
  }

  List<EditableAttachmentModel> buildSucceededPayload() {
    return _items
        .where((item) => item.isSucceeded && item.attachment != null)
        .map((item) => item.attachment!)
        .toList(growable: false);
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    try {
      while (true) {
        final nextItem = _items.cast<AttachmentUploadItem?>().firstWhere(
          (item) =>
              item != null && item.status == AttachmentUploadStatus.queued,
          orElse: () => null,
        );
        if (nextItem == null) {
          break;
        }

        final request = _queuedUploads[nextItem.localId];
        if (request == null) {
          _updateStatus(
            nextItem.localId,
            nextItem.copyWith(
              status: AttachmentUploadStatus.failed,
              errorMessage: 'Missing upload data.',
              clearAttachment: true,
            ),
          );
          continue;
        }

        try {
          Uint8List bytes = request.upload.bytes;
          if (request.upload.isImage) {
            _updateStatus(
              nextItem.localId,
              nextItem.copyWith(
                status: AttachmentUploadStatus.processing,
                clearErrorMessage: true,
                clearAttachment: true,
              ),
            );
            bytes = await _preprocessingService.preprocessImageForUpload(
              bytes: bytes,
              fileName: request.upload.fileName,
            );
          }

          _updateStatus(
            nextItem.localId,
            _itemById(nextItem.localId).copyWith(
              status: AttachmentUploadStatus.uploading,
              clearErrorMessage: true,
              clearAttachment: true,
            ),
          );

          final uploaded = await _uploadService.uploadPetDocument(
            bytes: bytes,
            petId: request.petId,
            fileName: request.upload.fileName,
            category: request.upload.category,
          );

          _updateStatus(
            nextItem.localId,
            _itemById(nextItem.localId).copyWith(
              status: AttachmentUploadStatus.succeeded,
              attachment: EditableAttachmentModel.fromUploaded(uploaded),
              clearErrorMessage: true,
            ),
          );
        } catch (error) {
          _updateStatus(
            nextItem.localId,
            _itemById(nextItem.localId).copyWith(
              status: AttachmentUploadStatus.failed,
              errorMessage: error.toString(),
              clearAttachment: true,
            ),
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  int _indexOfLocalId(String localId) {
    return _items.indexWhere((item) => item.localId == localId);
  }

  AttachmentUploadItem _itemById(String localId) {
    return _items.firstWhere((item) => item.localId == localId);
  }

  void _updateStatus(String localId, AttachmentUploadItem updatedItem) {
    final index = _indexOfLocalId(localId);
    if (index == -1) {
      return;
    }
    _items[index] = updatedItem;
    notifyListeners();
  }
}

class _QueuedAttachmentUpload {
  const _QueuedAttachmentUpload({required this.petId, required this.upload});

  final String petId;
  final PendingAttachmentUpload upload;
}
