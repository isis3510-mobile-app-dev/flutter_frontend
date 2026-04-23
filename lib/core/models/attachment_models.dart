import 'dart:typed_data';

class UploadedAttachmentModel {
  const UploadedAttachmentModel({
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    this.localFilePath,
  });

  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final String? localFilePath;
}

class EditableAttachmentModel {
  const EditableAttachmentModel({
    required this.fileName,
    required this.fileUri,
    this.localFilePath,
    this.storagePath = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.documentId,
  });

  final String fileName;
  final String fileUri;
  final String? localFilePath;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final String? documentId;

  factory EditableAttachmentModel.fromUploaded(
    UploadedAttachmentModel attachment,
  ) {
    return EditableAttachmentModel(
      fileName: attachment.fileName,
      fileUri: attachment.downloadUrl,
      localFilePath: attachment.localFilePath,
      storagePath: attachment.storagePath,
      contentType: attachment.contentType,
      sizeBytes: attachment.sizeBytes,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (documentId != null && documentId!.trim().isNotEmpty)
        'documentId': documentId,
      'fileName': fileName,
      'fileUri': fileUri,
      if (storagePath.trim().isNotEmpty) 'storagePath': storagePath,
      if (contentType.trim().isNotEmpty) 'contentType': contentType,
      if (sizeBytes > 0) 'sizeBytes': sizeBytes,
    };
  }
}

enum AttachmentUploadStatus { queued, processing, uploading, succeeded, failed }

class PendingAttachmentUpload {
  const PendingAttachmentUpload({
    required this.localId,
    required this.fileName,
    required this.bytes,
    required this.category,
    required this.isImage,
  });

  final String localId;
  final String fileName;
  final Uint8List bytes;
  final String category;
  final bool isImage;
}

class AttachmentUploadItem {
  const AttachmentUploadItem({
    required this.localId,
    required this.fileName,
    required this.status,
    this.errorMessage,
    this.attachment,
  });

  final String localId;
  final String fileName;
  final AttachmentUploadStatus status;
  final String? errorMessage;
  final EditableAttachmentModel? attachment;

  bool get isPending =>
      status == AttachmentUploadStatus.queued ||
      status == AttachmentUploadStatus.processing ||
      status == AttachmentUploadStatus.uploading;

  bool get isFailed => status == AttachmentUploadStatus.failed;
  bool get isSucceeded => status == AttachmentUploadStatus.succeeded;

  AttachmentUploadItem copyWith({
    String? localId,
    String? fileName,
    AttachmentUploadStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    EditableAttachmentModel? attachment,
    bool clearAttachment = false,
  }) {
    return AttachmentUploadItem(
      localId: localId ?? this.localId,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      attachment: clearAttachment ? null : (attachment ?? this.attachment),
    );
  }

  factory AttachmentUploadItem.fromExisting(
    EditableAttachmentModel attachment,
  ) {
    return AttachmentUploadItem(
      localId: attachment.documentId?.trim().isNotEmpty == true
          ? 'existing-${attachment.documentId!.trim()}'
          : 'existing-${attachment.fileName}-${attachment.fileUri}',
      fileName: attachment.fileName,
      status: AttachmentUploadStatus.succeeded,
      attachment: attachment,
    );
  }
}
