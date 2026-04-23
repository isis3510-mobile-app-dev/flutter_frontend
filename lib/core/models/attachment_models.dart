class UploadedAttachmentModel {
  const UploadedAttachmentModel({
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    this.localFilePath,
    this.isPendingUpload = false,
  });

  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final String? localFilePath;
  final bool isPendingUpload;
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
    this.isPendingUpload = false,
  });

  final String fileName;
  final String fileUri;
  final String? localFilePath;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final String? documentId;
  final bool isPendingUpload;

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
      isPendingUpload: attachment.isPendingUpload,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (documentId != null && documentId!.trim().isNotEmpty)
        'documentId': documentId,
      'fileName': fileName,
      'fileUri': fileUri,
      if (isPendingUpload &&
          localFilePath != null &&
          localFilePath!.trim().isNotEmpty)
        'localFilePath': localFilePath,
      if (storagePath.trim().isNotEmpty) 'storagePath': storagePath,
      if (contentType.trim().isNotEmpty) 'contentType': contentType,
      if (sizeBytes > 0) 'sizeBytes': sizeBytes,
      if (isPendingUpload) 'pendingUpload': true,
    };
  }
}
