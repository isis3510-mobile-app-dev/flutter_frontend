import 'package:flutter_frontend/core/models/medicine_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';

class MedicineDetailArgs {
  const MedicineDetailArgs({
    required this.medicine,
    required this.pet,
  });

  final MedicineModel medicine;
  final PetModel pet;
}