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
    String _readString(dynamic v) {
      if (v is String) return v;
      if (v == null) return '';
      return v.toString();
    }

    double? _readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? _readDate(dynamic v) {
      if (v is String && v.trim().isNotEmpty) {
        return DateTime.tryParse(v);
      }
      return null;
    }

    String? _readNullableString(dynamic v) {
      final s = _readString(v).trim();
      return s.isEmpty ? null : s;
    }

    return MedicineModel(
      id: _readString(json['medicineId'] ?? json['id'] ?? json['_id']),
      schema: (json['schema'] is int) ? json['schema'] as int : int.tryParse('${json['schema']}') ?? 1,
      petId: _readString(json['petId'] ?? json['pet_id']),
      ownerId: _readString(json['ownerId'] ?? json['owner_id']),
      medicineName: _readString(json['medicineName'] ?? json['medicine_name']),
      administrationRoute: _readString(json['administrationRoute'] ?? json['administration_route']),
      dosageValue: _readDouble(json['dosageValue'] ?? json['dosage_value']),
      dosageUnit: _readString(json['dosageUnit'] ?? json['dosage_unit']),
      frequency: (json['frequency'] is int) ? json['frequency'] as int : int.tryParse('${json['frequency']}') ?? 0,
      startDate: _readDate(json['startDate'] ?? json['start_date']),
      endDate: _readDate(json['endDate'] ?? json['end_date']),
      photoUrl: _readNullableString(json['photoUrl'] ?? json['photo_url']),
      reminderEnabled: (json['reminderEnabled'] is bool)
          ? json['reminderEnabled'] as bool
          : ((json['reminder_enabled'] is bool) ? json['reminder_enabled'] as bool : false),
      lastAdministered: _readDate(json['lastAdministered'] ?? json['last_administered']),
    );
  }
}
