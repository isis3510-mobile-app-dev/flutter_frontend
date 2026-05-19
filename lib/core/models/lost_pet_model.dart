class LostPetContactModel {
  const LostPetContactModel({
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.relationship,
    required this.isPrimary,
    required this.allowCall,
    required this.allowWhatsApp,
  });

  final String name;
  final String phone;
  final String whatsapp;
  final String relationship;
  final bool isPrimary;
  final bool allowCall;
  final bool allowWhatsApp;

  factory LostPetContactModel.fromJson(Map<String, dynamic> json) {
    final phone = _readStringByKeys(json, const ['phone']);
    final whatsapp = _readStringByKeys(json, const ['whatsapp']);

    return LostPetContactModel(
      name: _readStringByKeys(json, const ['name']),
      phone: phone,
      whatsapp: whatsapp,
      relationship: _readStringByKeys(json, const [
        'relationship',
      ], fallback: 'Emergency contact'),
      isPrimary: _readBoolByKeys(json, const [
        'isPrimary',
        'is_primary',
        'preferred',
      ]),
      allowCall: _readBoolByKeys(json, const [
        'allowCall',
        'allow_call',
        'exposePhone',
        'expose_phone',
      ], fallback: phone.trim().isNotEmpty),
      allowWhatsApp: _readBoolByKeys(json, const [
        'allowWhatsApp',
        'allow_whatsapp',
        'exposeWhatsapp',
        'expose_whatsapp',
      ], fallback: whatsapp.trim().isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'allowCall': allowCall,
      'allowWhatsApp': allowWhatsApp,
    };
  }
}

class LostPetLocationModel {
  const LostPetLocationModel({
    this.name = '',
    this.latitude,
    this.longitude,
    this.source = '',
    this.accuracyMeters,
    this.seenAt,
  });

  final String name;
  final double? latitude;
  final double? longitude;
  final String source;
  final double? accuracyMeters;
  final DateTime? seenAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory LostPetLocationModel.fromJson(Map<String, dynamic> json) {
    return LostPetLocationModel(
      name: _readStringByKeys(json, const [
        'name',
        'location',
        'locationName',
        'location_name',
        'lastSeenLocation',
        'lastSeenLocationName',
      ]),
      latitude: _readDoubleByKeys(json, const [
        'latitude',
        'lat',
        'lastSeenLat',
        'last_seen_lat',
        'lastSeenLatitude',
      ]),
      longitude: _readDoubleByKeys(json, const [
        'longitude',
        'lng',
        'lastSeenLng',
        'last_seen_lng',
        'lastSeenLongitude',
      ]),
      source: _readStringByKeys(json, const [
        'source',
        'lastSeenSource',
        'last_seen_source',
      ]),
      accuracyMeters: _readDoubleByKeys(json, const [
        'accuracyMeters',
        'accuracy_meters',
      ]),
      seenAt: _parseDate(
        _readValueByKeys(json, const ['seenAt', 'seen_at', 'lastSeenAt']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
      'accuracyMeters': accuracyMeters,
      'seenAt': seenAt?.toIso8601String(),
    };
  }
}

class LostPetReportModel {
  const LostPetReportModel({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.city,
    required this.status,
    required this.petName,
    required this.species,
    required this.breed,
    required this.gender,
    required this.color,
    this.weight,
    this.ageLabel = '',
    this.photoUrl,
    this.knownAllergies = '',
    this.defaultVet = '',
    this.defaultClinic = '',
    this.microchipId = '',
    this.lostNote = '',
    this.exposeMedicalInfo = false,
    this.nfcNotificationsEnabled = true,
    required this.lastSeen,
    required this.contacts,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  final String id;
  final String petId;
  final String ownerId;
  final String city;
  final String status;
  final String petName;
  final String species;
  final String breed;
  final String gender;
  final String color;
  final double? weight;
  final String ageLabel;
  final String? photoUrl;
  final String knownAllergies;
  final String defaultVet;
  final String defaultClinic;
  final String microchipId;
  final String lostNote;
  final bool exposeMedicalInfo;
  final bool nfcNotificationsEnabled;
  final LostPetLocationModel lastSeen;
  final List<LostPetContactModel> contacts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  bool get isActive => status == 'active';

  LostPetContactModel? get primaryContact {
    for (final contact in contacts) {
      if (contact.isPrimary) {
        return contact;
      }
    }
    return contacts.isEmpty ? null : contacts.first;
  }

  factory LostPetReportModel.fromJson(Map<String, dynamic> json) {
    final contactsJson = _readListByKeys(json, const [
      'contacts',
      'emergencyContacts',
      'emergency_contacts',
    ]);
    final locationJson = _readLocationJson(json);
    final petJson = _asStringDynamicMap(_readValueByKeys(json, const ['pet']));

    return LostPetReportModel(
      id: _readStringByKeys(json, const ['id', '_id']),
      petId: _readStringByKeys(json, const ['petId', 'pet_id']).isNotEmpty
          ? _readStringByKeys(json, const ['petId', 'pet_id'])
          : _readStringByKeys(petJson, const ['id', '_id']),
      ownerId: _readStringByKeys(json, const ['ownerId', 'owner_id']),
      city: _readStringByKeys(json, const ['city'], fallback: 'Bogotá'),
      status: _readStringByKeys(json, const ['status'], fallback: 'active'),
      petName:
          _readStringByKeys(json, const [
            'petName',
            'pet_name',
            'name',
          ]).isNotEmpty
          ? _readStringByKeys(json, const ['petName', 'pet_name', 'name'])
          : _readStringByKeys(petJson, const ['name']),
      species: _readStringByKeys(json, const ['species']).isNotEmpty
          ? _readStringByKeys(json, const ['species'])
          : _readStringByKeys(petJson, const ['species']),
      breed: _readStringByKeys(json, const ['breed']).isNotEmpty
          ? _readStringByKeys(json, const ['breed'])
          : _readStringByKeys(petJson, const ['breed']),
      gender: _readStringByKeys(json, const ['gender']).isNotEmpty
          ? _readStringByKeys(json, const ['gender'])
          : _readStringByKeys(petJson, const ['gender']),
      color: _readStringByKeys(json, const ['color']).isNotEmpty
          ? _readStringByKeys(json, const ['color'])
          : _readStringByKeys(petJson, const ['color']),
      weight:
          _readDoubleByKeys(json, const ['weight']) ??
          _readDoubleByKeys(petJson, const ['weight']),
      ageLabel: _readStringByKeys(json, const ['ageLabel', 'age_label']),
      photoUrl: _readNullableString(
        _readValueByKeys(json, const ['photoUrl', 'photo_url']) ??
            _readValueByKeys(petJson, const ['photoUrl', 'photo_url']),
      ),
      knownAllergies: _readStringByKeys(json, const [
        'knownAllergies',
        'known_allergies',
      ]),
      defaultVet: _readStringByKeys(json, const ['defaultVet', 'default_vet']),
      defaultClinic: _readStringByKeys(json, const [
        'defaultClinic',
        'default_clinic',
      ]),
      microchipId: _readStringByKeys(json, const [
        'microchipId',
        'microchip_id',
      ]),
      lostNote: _readStringByKeys(json, const [
        'lostNote',
        'lost_note',
        'note',
      ]),
      exposeMedicalInfo: _readBoolByKeys(json, const [
        'exposeMedicalInfo',
        'expose_medical_info',
      ]),
      nfcNotificationsEnabled: _readBoolByKeys(json, const [
        'nfcNotificationsEnabled',
        'nfc_notifications_enabled',
      ], fallback: true),
      lastSeen: LostPetLocationModel.fromJson(locationJson),
      contacts: contactsJson
          .map(_asStringDynamicMap)
          .map(LostPetContactModel.fromJson)
          .toList(growable: false),
      createdAt: _parseDate(_readValueByKeys(json, const ['createdAt'])),
      updatedAt: _parseDate(_readValueByKeys(json, const ['updatedAt'])),
      resolvedAt: _parseDate(_readValueByKeys(json, const ['resolvedAt'])),
    );
  }
}

Map<String, dynamic> _readLocationJson(Map<String, dynamic> json) {
  final nested = _readValueByKeys(json, const [
    'lastSeen',
    'last_seen',
    'location',
  ]);
  if (nested is Map<String, dynamic>) {
    return nested;
  }
  if (nested is Map) {
    return nested.map((key, value) => MapEntry(key.toString(), value));
  }
  return json;
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

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
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

double? _readDoubleByKeys(Map<String, dynamic> json, List<String> keys) {
  return _readDouble(_readValueByKeys(json, keys));
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
  bool fallback = false,
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
