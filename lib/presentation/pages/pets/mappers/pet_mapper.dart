import '../models/pet_ui_model.dart';

/// Converts raw backend JSON (snake_case) to [PetUiModel] (camelCase).
abstract class PetMapper {
  static PetUiModel fromJson(Map<String, dynamic> json) {
    return PetUiModel(
      id: _readString(json, ['id', '_id']),
      userIds: (json['user_ids'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      name: _readString(json, ['name'], fallback: 'Unnamed Pet'),
      species: _readString(json, ['species'], fallback: 'Unknown'),
      breed: _readString(json, ['breed'], fallback: 'Unknown breed'),
      gender: _readString(json, ['gender'], fallback: 'Unknown'),
      birthDate: _readDate(json['birth_date']),
      weight: _readDouble(json['weight']),
      color: _readString(json, ['color'], fallback: 'Unknown'),
      photoUrl: _readNullableString(json, ['photo_url', 'photoUrl']),
      status: _normalizeStatus(
        _readString(json, ['status'], fallback: 'needs attention'),
      ),
      isNfcSynced: json['is_nfc_synced'] == true,
      knownAllergies: json['known_allergies'] as String? ?? '',
      defaultVet: json['default_vet'] as String? ?? '',
      defaultClinic: json['default_clinic'] as String? ?? '',
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }

  static DateTime _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime(2000, 1, 1);
    }
    return DateTime(2000, 1, 1);
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'healthy' || normalized == 'lost') {
      return normalized;
    }
    return 'needs attention';
  }
}
