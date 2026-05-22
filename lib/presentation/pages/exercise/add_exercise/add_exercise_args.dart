import 'package:flutter_frontend/core/models/exercise_model.dart';

class AddExerciseArgs {
  const AddExerciseArgs({
    required this.petId,
    required this.petName,
    this.prefilledType,
    this.prefilledStartedAt,
    this.prefilledDurationMinutes,
    this.editingExercise,
  });

  final String petId;
  final String petName;
  final String? prefilledType;
  final DateTime? prefilledStartedAt;
  final int? prefilledDurationMinutes;
  final ExerciseModel? editingExercise;
}
