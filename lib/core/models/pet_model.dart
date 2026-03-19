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
      documentId: _readStringByKeys(
        json,
        const ['documentId', 'document_id', 'id', '_id'],
      ),
      fileName: _readStringByKeys(
        json,
        const ['fileName', 'file_name', 'name'],
      ),
      fileUri: _readStringByKeys(
        json,
        const ['fileUri', 'file_uri', 'fileUrl', 'url', 'uri'],
      ),
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
    final attachedDocumentsJson = _readListByKeys(
      json,
      const ['attachedDocuments', 'attached_documents'],
    );

    return PetVaccinationModel(
      id: _readStringByKeys(json, const ['id', '_id']),
      vaccineId: _readStringByKeys(json, const ['vaccineId', 'vaccine_id']),
      dateGiven: _parseDate(_readValueByKeys(json, const ['dateGiven', 'date_given'])),
      nextDueDate: _parseDate(
        _readValueByKeys(json, const ['nextDueDate', 'next_due_date']),
      ),
      lotNumber: _readStringByKeys(json, const ['lotNumber', 'lot_number']),
      status: _readStringByKeys(json, const ['status']),
      administeredBy: _readStringByKeys(
        json,
        const ['administeredBy', 'administered_by'],
      ),
      clinicName: _readStringByKeys(json, const ['clinicName', 'clinic_name']),
      attachedDocuments: attachedDocumentsJson
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
      id: _readStringByKeys(json, const ['id', '_id']),
      schema: _readInt(json['schema'], fallback: 1),
      owners: ownersJson == null
          ? const []
          : ownersJson.map((item) => item.toString()).toList(growable: false),
      name: _readStringByKeys(json, const ['name']),
      species: _readStringByKeys(json, const ['species']),
      breed: _readStringByKeys(json, const ['breed']),
      gender: _readStringByKeys(json, const ['gender']),
      birthDate: _parseDate(_readValueByKeys(json, const ['birthDate', 'birth_date'])),
      weight: _readDouble(json['weight']),
      color: _readStringByKeys(json, const ['color']),
      photoUrl: _readNullableString(
        _readValueByKeys(json, const ['photoUrl', 'photo_url']),
      ),
      status: _readStringByKeys(json, const ['status'], fallback: 'healthy'),
      isNfcSynced: _readBoolByKeys(
        json,
        const ['isNfcSynced', 'is_nfc_synced'],
        fallback: false,
      ),
      knownAllergies: _readStringByKeys(
        json,
        const ['knownAllergies', 'known_allergies'],
      ),
      defaultVet: _readStringByKeys(json, const ['defaultVet', 'default_vet']),
      defaultClinic: _readStringByKeys(
        json,
        const ['defaultClinic', 'default_clinic'],
      ),
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

bool _readBoolByKeys(
  Map<String, dynamic> json,
  List<String> keys, {
  required bool fallback,
}) {
  final value = _readValueByKeys(json, keys);
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }

  return fallback;
}

List<dynamic> _readListByKeys(Map<String, dynamic> json, List<String> keys) {
  final value = _readValueByKeys(json, keys);
  if (value is List) {
    return value;
  }
  return const [];
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

  return _readString(value, fallback: fallback);
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
