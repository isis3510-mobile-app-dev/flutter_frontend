import 'package:flutter_frontend/core/models/exercise_model.dart';

class ExerciseDetailArgs {
  const ExerciseDetailArgs({
    required this.exercise,
    required this.petName,
  });

  final ExerciseModel exercise;
  final String petName;
}
