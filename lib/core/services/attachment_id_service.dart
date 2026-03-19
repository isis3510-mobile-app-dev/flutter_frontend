class AttachmentIdService {
  AttachmentIdService._();

  static final AttachmentIdService _instance = AttachmentIdService._();

  factory AttachmentIdService() => _instance;

  String buildProfilePhotoPath({
    required String firebaseUid,
    required String originalFileName,
  }) {
    final normalizedUid = firebaseUid.trim();
    final extension = extensionFromName(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'users/$normalizedUid/profile/profile_$timestamp.$extension';
  }

  String buildPetPhotoPath({
    required String petId,
    required String originalFileName,
  }) {
    final normalizedPetId = petId.trim();
    final extension = extensionFromName(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'pets/$normalizedPetId/photo/pet_$timestamp.$extension';
  }

  String buildPetDocumentPath({
    required String petId,
    required String originalFileName,
    String category = 'general',
  }) {
    final normalizedPetId = petId.trim();
    final normalizedCategory = sanitizePathSegment(category);
    final extension = extensionFromName(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'pets/$normalizedPetId/documents/$normalizedCategory/doc_$timestamp.$extension';
  }

  String extensionFromName(String fileName) {
    final sanitized = sanitizeFileName(fileName);
    final dotIndex = sanitized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == sanitized.length - 1) {
      return 'jpg';
    }

    return sanitized.substring(dotIndex + 1).toLowerCase();
  }

  String sanitizeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return 'file.jpg';
    }

    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String sanitizePathSegment(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return 'general';
    }

    return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}
