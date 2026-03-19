/// UI model for a pet.
/// Kept intentionally framework-agnostic so it can be backed by mock data
/// now and by a repository/service layer later.
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
    this.localPhotoPath,
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
  final String? localPhotoPath;

  /// 'healthy' | 'needs attention' | 'lost'
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
    final years =
        now.year -
        birthDate.year -
        (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)
            ? 1
            : 0);
    if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
    final months =
        ((now.year - birthDate.year) * 12 + (now.month - birthDate.month))
            .clamp(0, 11);
    if (months > 0) return '$months mo';
    return '< 1 mo';
  }

  /// Human-readable weight, e.g. "12.0 kg".
  String get weightLabel => '${weight.toStringAsFixed(1)} kg';

  String? get effectivePhotoPath {
    final local = localPhotoPath?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    final remote = photoUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }

    return null;
  }

  bool get hasPhoto => effectivePhotoPath != null;

  bool get isPhotoRemote {
    final value = effectivePhotoPath;
    if (value == null) {
      return false;
    }

    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  PetUiModel copyWith({String? localPhotoPath, String? photoUrl}) {
    return PetUiModel(
      id: id,
      userIds: userIds,
      name: name,
      species: species,
      breed: breed,
      gender: gender,
      birthDate: birthDate,
      weight: weight,
      color: color,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      status: status,
      isNfcSynced: isNfcSynced,
      knownAllergies: knownAllergies,
      defaultVet: defaultVet,
      defaultClinic: defaultClinic,
    );
  }
}
