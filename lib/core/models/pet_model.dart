class PetDocumentModel {
  const PetDocumentModel({
    required this.documentId,
    required this.fileName,
    required this.fileUri,
  });

  final String documentId;
  final String fileName;
  final String fileUri;

  factory PetDocumentModel.fromJson(Map<String, dynamic> json) {
    return PetDocumentModel(
      documentId: _readString(json['documentId']),
      fileName: _readString(json['fileName']),
      fileUri: _readString(json['fileUri']),
    );
  }
}

class PetVaccinationModel {
  const PetVaccinationModel({
    required this.id,
    required this.vaccineId,
    required this.dateGiven,
    required this.nextDueDate,
    required this.lotNumber,
    required this.status,
    required this.administeredBy,
    required this.clinicName,
    required this.attachedDocuments,
  });

  final String id;
  final String vaccineId;
  final DateTime dateGiven;
  final DateTime nextDueDate;
  final String lotNumber;
  final String status;
  final String administeredBy;
  final String clinicName;
  final List<PetDocumentModel> attachedDocuments;

  factory PetVaccinationModel.fromJson(Map<String, dynamic> json) {
    final attachedDocumentsJson = json['attachedDocuments'] as List<dynamic>?;

    return PetVaccinationModel(
      id: _readString(json['id']),
      vaccineId: _readString(json['vaccineId']),
      dateGiven: _parseDate(json['dateGiven']),
      nextDueDate: _parseDate(json['nextDueDate']),
      lotNumber: _readString(json['lotNumber']),
      status: _readString(json['status']),
      administeredBy: _readString(json['administeredBy']),
      clinicName: _readString(json['clinicName']),
      attachedDocuments: attachedDocumentsJson == null
          ? const []
          : attachedDocumentsJson
                .map(_asStringDynamicMap)
                .map(PetDocumentModel.fromJson)
                .toList(growable: false),
    );
  }
}

class PetModel {
  const PetModel({
    required this.id,
    required this.schema,
    required this.owners,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.color,
    required this.photoUrl,
    required this.status,
    required this.isNfcSynced,
    required this.knownAllergies,
    required this.defaultVet,
    required this.defaultClinic,
    required this.vaccinations,
  });

  final String id;
  final int schema;
  final List<String> owners;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final DateTime? birthDate;
  final double? weight;
  final String color;
  final String? photoUrl;
  final String status;
  final bool isNfcSynced;
  final String knownAllergies;
  final String defaultVet;
  final String defaultClinic;
  final List<PetVaccinationModel> vaccinations;

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final ownersJson = json['owners'] as List<dynamic>?;
    final vaccinationsJson = json['vaccinations'] as List<dynamic>?;

    return PetModel(
      id: _readString(json['id']),
      schema: _readInt(json['schema'], fallback: 1),
      owners: ownersJson == null
          ? const []
          : ownersJson.map((item) => item.toString()).toList(growable: false),
      name: _readString(json['name']),
      species: _readString(json['species']),
      breed: _readString(json['breed']),
      gender: _readString(json['gender']),
      birthDate: _parseDate(json['birthDate']),
      weight: _readDouble(json['weight']),
      color: _readString(json['color']),
      photoUrl: _readNullableString(json['photoUrl']),
      status: _readString(json['status'], fallback: 'healthy'),
      isNfcSynced: json['isNfcSynced'] as bool? ?? false,
      knownAllergies: _readString(json['knownAllergies']),
      defaultVet: _readString(json['defaultVet']),
      defaultClinic: _readString(json['defaultClinic']),
      vaccinations: vaccinationsJson == null
          ? const []
          : vaccinationsJson
                .map(_asStringDynamicMap)
                .map(PetVaccinationModel.fromJson)
                .toList(growable: false),
    );
  }
}

Map<String, dynamic> _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return const <String, dynamic>{};
}

DateTime _parseDate(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    return DateTime(0);
  }

  return DateTime.tryParse(value) ?? DateTime(0);
}

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

int _readInt(dynamic value, {required int fallback}) {
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

String _readString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }

  if (value == null) {
    return fallback;
  }

  return value.toString();
}

String? _readNullableString(dynamic value) {
  final text = _readString(value).trim();
  return text.isEmpty ? null : text;
}
