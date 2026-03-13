/// UI model for a pet.
/// Field names are camelCase, mapping 1-to-1 with the backend JSON schema
/// (snake_case). See [PetMapper.fromJson] for the conversion.
class PetUiModel {
  const PetUiModel({
    required this.id,
    required this.userIds,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.color,
    this.photoUrl,
    required this.status,
    required this.isNfcSynced,
    required this.knownAllergies,
    required this.defaultVet,
    required this.defaultClinic,
  });

  final String id;
  final List<String> userIds;
  final String name;

  /// 'Dog' | 'Cat'
  final String species;
  final String breed;

  /// 'Male' | 'Female'
  final String gender;
  final DateTime birthDate;
  final double weight;
  final String color;
  final String? photoUrl;

  /// 'healthy' | 'needs attention'
  final String status;
  final bool isNfcSynced;
  final String knownAllergies;
  final String defaultVet;
  final String defaultClinic;

  // --- Computed display helpers ---

  bool get isHealthy => status == 'healthy';

  /// Human-readable age, e.g. "4 yrs" or "3 mo".
  String get ageLabel {
    final now = DateTime.now();
    final years = now.year -
        birthDate.year -
        (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)
            ? 1
            : 0);
    if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
    final months = ((now.year - birthDate.year) * 12 +
            (now.month - birthDate.month))
        .clamp(0, 11);
    if (months > 0) return '$months mo';
    return '< 1 mo';
  }

  /// Human-readable weight, e.g. "12.0 kg".
  String get weightLabel => '${weight.toStringAsFixed(1)} kg';
}
