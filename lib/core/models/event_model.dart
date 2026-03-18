class EventDocumentModel {
  const EventDocumentModel({
    required this.documentId,
    required this.fileName,
    required this.fileUri,
  });

  final String documentId;
  final String fileName;
  final String fileUri;

  factory EventDocumentModel.fromJson(Map<String, dynamic> json) {
    return EventDocumentModel(
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

class EventModel {
  const EventModel({
    required this.id,
    required this.schema,
    required this.petId,
    required this.ownerId,
    required this.title,
    required this.eventType,
    required this.date,
    required this.price,
    required this.provider,
    required this.clinic,
    required this.description,
    required this.followUpDate,
    required this.attachedDocuments,
  });

  final String id;
  final int schema;
  final String petId;
  final String ownerId;
  final String title;
  final String eventType;
  final DateTime date;
  final double? price;
  final String provider;
  final String clinic;
  final String description;
  final DateTime? followUpDate;
  final List<EventDocumentModel> attachedDocuments;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final attachedDocumentsJson = _readListByKeys(
      json,
      const ['attachedDocuments', 'attached_documents'],
    );

    return EventModel(
      id: _readStringByKeys(json, const ['id', '_id']),
      schema: _readIntByKeys(json, const ['schema'], fallback: 1),
      petId: _readStringByKeys(json, const ['petId', 'pet_id']),
      ownerId: _readStringByKeys(json, const ['ownerId', 'owner_id']),
      title: _readStringByKeys(json, const ['title']),
      eventType: _readStringByKeys(
        json,
        const ['eventType', 'event_type'],
        fallback: 'general',
      ),
      date: _readDateByKeys(json, const ['date']),
      price: _readDoubleByKeys(json, const ['price']),
      provider: _readStringByKeys(json, const ['provider']),
      clinic: _readStringByKeys(json, const ['clinic']),
      description: _readStringByKeys(json, const ['description']),
      followUpDate: _readNullableDateByKeys(
        json,
        const ['followUpDate', 'follow_up_date'],
      ),
      attachedDocuments: attachedDocumentsJson
          .map(_asStringDynamicMap)
          .map(EventDocumentModel.fromJson)
          .toList(growable: false),
    );
  }
}

List<dynamic> _readListByKeys(Map<String, dynamic> json, List<String> keys) {
  final value = _readValueByKeys(json, keys);
  if (value is List) {
    return value;
  }
  return const [];
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

Map<String, dynamic> _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}
