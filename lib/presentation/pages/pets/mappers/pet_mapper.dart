import '../models/pet_ui_model.dart';

/// Converts raw backend JSON (snake_case) to [PetUiModel] (camelCase).
abstract class PetMapper {
  static PetUiModel fromJson(Map<String, dynamic> json) {
    return PetUiModel(
      id: json['id'] as String,
      userIds: (json['user_ids'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String,
      gender: json['gender'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      weight: (json['weight'] as num).toDouble(),
      color: json['color'] as String,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      isNfcSynced: json['is_nfc_synced'] as bool,
      knownAllergies: json['known_allergies'] as String? ?? '',
      defaultVet: json['default_vet'] as String? ?? '',
      defaultClinic: json['default_clinic'] as String? ?? '',
    );
  }
}
