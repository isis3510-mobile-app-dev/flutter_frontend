class MedicineModel {
  const MedicineModel({
    required this.id,
    required this.schema,
    required this.petId,
    required this.ownerId,
    required this.medicineName,
    required this.administrationRoute,
    required this.dosageValue,
    required this.dosageUnit,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.photoUrl,
    required this.reminderEnabled,
    required this.lastAdministered,
  });

  final String id;
  final int schema;
  final String petId;
  final String ownerId;
  final String medicineName;
  final String administrationRoute;
  final double? dosageValue;
  final String dosageUnit;
  final int frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? photoUrl;
  final bool reminderEnabled;
  final DateTime? lastAdministered;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    String readString(dynamic v) {
      if (v is String) return v;
      if (v == null) return '';
      return v.toString();
    }

    double? readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? readDate(dynamic v) {
      if (v is String && v.trim().isNotEmpty) {
        return DateTime.tryParse(v);
      }
      return null;
    }

    String? readNullableString(dynamic v) {
      final s = readString(v).trim();
      return s.isEmpty ? null : s;
    }

    return MedicineModel(
      id: readString(json['medicineId'] ?? json['id'] ?? json['_id']),
      schema: (json['schema'] is int) ? json['schema'] as int : int.tryParse('${json['schema']}') ?? 1,
      petId: readString(json['petId'] ?? json['pet_id']),
      ownerId: readString(json['ownerId'] ?? json['owner_id']),
      medicineName: readString(json['medicineName'] ?? json['medicine_name']),
      administrationRoute: readString(json['administrationRoute'] ?? json['administration_route']),
      dosageValue: readDouble(json['dosageValue'] ?? json['dosage_value']),
      dosageUnit: readString(json['dosageUnit'] ?? json['dosage_unit']),
      frequency: (json['frequency'] is int) ? json['frequency'] as int : int.tryParse('${json['frequency']}') ?? 0,
      startDate: readDate(json['startDate'] ?? json['start_date']),
      endDate: readDate(json['endDate'] ?? json['end_date']),
      photoUrl: readNullableString(json['photoUrl'] ?? json['photo_url']),
      reminderEnabled: (json['reminderEnabled'] is bool)
          ? json['reminderEnabled'] as bool
          : ((json['reminder_enabled'] is bool) ? json['reminder_enabled'] as bool : false),
      lastAdministered: readDate(json['lastAdministered'] ?? json['last_administered']),
    );
  }
}
