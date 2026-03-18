import '../models/pet_ui_model.dart';

class PetDetailArgs {
  const PetDetailArgs({
    required this.pet,
    this.initialTabIndex = 0,
  });

  final PetUiModel pet;
  final int initialTabIndex;
}
