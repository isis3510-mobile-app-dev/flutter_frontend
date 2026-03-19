class UploadedAttachmentModel {
  const UploadedAttachmentModel({
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
  });

  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
}

class EditableAttachmentModel {
  const EditableAttachmentModel({
    required this.fileName,
    required this.fileUri,
    this.storagePath = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.documentId,
  });

  final String fileName;
  final String fileUri;
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
