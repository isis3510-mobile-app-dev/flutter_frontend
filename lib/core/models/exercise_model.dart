class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.type,
    required this.startedAt,
    required this.durationMinutes,
    required this.intensity,
    required this.distanceKm,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String ownerId;
  final String type;
  final DateTime startedAt;
  final int durationMinutes;
  final String intensity;
  final double? distanceKm;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get endedAt => startedAt.add(Duration(minutes: durationMinutes));

  ExerciseModel copyWith({
    String? id,
    String? petId,
    String? ownerId,
    String? type,
    DateTime? startedAt,
    int? durationMinutes,
    String? intensity,
    double? distanceKm,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      distanceKm: distanceKm ?? this.distanceKm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: _readStringByKeys(json, const ['id', '_id']),
      petId: _readStringByKeys(json, const ['petId', 'pet_id']),
      ownerId: _readStringByKeys(json, const ['ownerId', 'owner_id']),
      type: _readStringByKeys(json, const ['type'], fallback: 'walk'),
      startedAt: _readDateByKeys(
        json,
        const ['startedAt', 'started_at', 'date'],
      ),
      durationMinutes: _readIntByKeys(
        json,
        const ['durationMinutes', 'duration_minutes', 'duration'],
        fallback: 0,
      ),
      intensity: _readStringByKeys(
        json,
        const ['intensity'],
        fallback: 'medium',
      ),
      distanceKm: _readDoubleByKeys(
        json,
        const ['distanceKm', 'distance_km', 'distance'],
      ),
      notes: _readStringByKeys(json, const ['notes']),
      createdAt: _readNullableDateByKeys(
            json,
            const ['createdAt', 'created_at'],
          ) ??
          _readDateByKeys(json, const ['startedAt', 'started_at', 'date']),
      updatedAt: _readNullableDateByKeys(
            json,
            const ['updatedAt', 'updated_at'],
          ) ??
          _readDateByKeys(json, const ['startedAt', 'started_at', 'date']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'petId': petId,
      'ownerId': ownerId,
      'type': type,
      'startedAt': startedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'distanceKm': distanceKm,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ExerciseWeeklySummary {
  const ExerciseWeeklySummary({
    required this.totalMinutes,
    required this.sessionCount,
    required this.totalDistanceKm,
  });

  final int totalMinutes;
  final int sessionCount;
  final double totalDistanceKm;
}

double? _readDoubleByKeys(Map<String, dynamic> json, List<String> keys) {
  final value = _readValueByKeys(json, keys);
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime _readDateByKeys(Map<String, dynamic> json, List<String> keys) {
  final value = _readValueByKeys(json, keys);
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim()) ?? DateTime(0);
  }
  return DateTime(0);
}

DateTime? _readNullableDateByKeys(Map<String, dynamic> json, List<String> keys) {
  final value = _readValueByKeys(json, keys);
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

int _readIntByKeys(
  Map<String, dynamic> json,
  List<String> keys, {
  required int fallback,
}) {
  final value = _readValueByKeys(json, keys);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _readStringByKeys(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  final value = _readValueByKeys(json, keys);
  final idFromMap = _readObjectIdFromMap(value);
  if (idFromMap != null) {
    return idFromMap;
  }

  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

dynamic _readValueByKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

String? _readObjectIdFromMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  final oid = value['\$oid'];
  if (oid is String && oid.trim().isNotEmpty) {
    return oid;
  }

  final nestedId = value['id'] ?? value['_id'];
  if (nestedId is String && nestedId.trim().isNotEmpty) {
    return nestedId;
  }

  return null;
}
