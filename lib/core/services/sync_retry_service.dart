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

  Future<void> retryPendingWrites({int limitPerEntity = 30}) async {
    await _userService.retryPendingSyncOperations(limit: limitPerEntity);
    await _petService.retryPendingSyncOperations(limit: limitPerEntity);
    await _eventService.retryPendingSyncOperations(limit: limitPerEntity);
  }
}
