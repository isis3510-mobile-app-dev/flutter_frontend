
class AddMedicineArgs {
  const AddMedicineArgs({
    this.medicineId,
    this.petId,
    this.petName,
    this.medicineName,
    this.administrationRoute,
    this.dosageValue,
    this.dosageUnit,
    this.frequency,
    this.startDate,
    this.endDate,
    this.photoUrl,
    this.reminderEnabled,
    this.lastAdministered,
  });

  final String? medicineId;
  final String? petId;
  final String? petName;
  final String? medicineName;
  final String? administrationRoute;
  final double? dosageValue;
  final String? dosageUnit;
  final int? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? photoUrl;
  final bool? reminderEnabled;
  final DateTime? lastAdministered;
}
