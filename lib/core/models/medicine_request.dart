class MedicineRequest {
  const MedicineRequest({
    required this.petId,
    required this.medicineName,
    required this.administrationRoute,
    required this.dosageValue,
    required this.dosageUnit,
    required this.frequency,
    required this.reminderEnabled,
    this.startDate,
    this.endDate,
    this.photoUrl,
    this.lastAdministered,
  });

  final String petId;
  final String medicineName;
  final String administrationRoute;
  final double dosageValue;
  final String dosageUnit;
  final int frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? photoUrl;
  final bool reminderEnabled;
  final DateTime? lastAdministered;

  Map<String, dynamic> toJson() {
    final photoValue = photoUrl?.trim() ?? '';

    return <String, dynamic>{
      'petId': petId.trim(),
      'medicineName': medicineName.trim(),
      'administrationRoute': administrationRoute.trim(),
      'dosageValue': dosageValue,
      'dosageUnit': dosageUnit.trim(),
      'frequency': frequency,
      if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
      if (photoValue.isNotEmpty) 'photoUrl': photoValue,
      'reminderEnabled': reminderEnabled,
      if (lastAdministered != null)
        'lastAdministered': lastAdministered!.toUtc().toIso8601String(),
      'schema': 1,
    };
  }
}