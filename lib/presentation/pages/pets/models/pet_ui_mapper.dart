import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/pet_model.dart';
import 'pet_ui_model.dart';

extension PetUiMapper on PetModel {
  PetUiModel toUiModel() {
    return PetUiModel(
      id: id,
      userIds: owners,
      name: _displayOrFallback(name),
      species: _normalizeSpecies(species),
      breed: _displayOrFallback(breed),
      gender: _normalizeGender(gender),
      birthDate: birthDate ?? DateTime.now(),
      weight: weight ?? 0,
      color: _displayOrFallback(color),
      photoUrl: photoUrl,
      status: status.isEmpty ? 'healthy' : status,
      isNfcSynced: isNfcSynced,
      knownAllergies: _displayOrFallback(knownAllergies),
      defaultVet: _displayOrFallback(defaultVet),
      defaultClinic: _displayOrFallback(defaultClinic),
    );
  }
}

String _displayOrFallback(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? AppStrings.valueNotAvailable : normalized;
}

String _normalizeGender(String value) {
  return switch (value.trim().toLowerCase()) {
    'male' => 'Male',
    'female' => 'Female',
    _ => _displayOrFallback(value),
  };
}

String _normalizeSpecies(String value) {
  return switch (value.trim().toLowerCase()) {
    'dog' => 'Dog',
    'cat' => 'Cat',
    'rabbit' => 'Rabbit',
    _ => _displayOrFallback(value),
  };
}
