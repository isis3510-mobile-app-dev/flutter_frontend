import 'attachment_upload_service.dart';
import 'pet_service.dart';
import 'event_service.dart';
import 'user_service.dart';

class SyncRetryService {
  SyncRetryService._();

  static final SyncRetryService _instance = SyncRetryService._();

  factory SyncRetryService() => _instance;

  final PetService _petService = PetService();
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();

  Future<void> retryPendingWrites({int limitPerEntity = 30}) async {
    await _attachmentUploadService.retryPendingSyncOperations(
      limit: limitPerEntity,
    );
    await _userService.retryPendingSyncOperations(limit: limitPerEntity);
    await _petService.retryPendingSyncOperations(limit: limitPerEntity);
    await _eventService.retryPendingSyncOperations(limit: limitPerEntity);
  }
}
