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
      documentId: _readString(
        json['documentId'] ?? json['document_id'] ?? json['id'],
      ),
      fileName: _readString(
        json['fileName'] ?? json['file_name'] ?? json['name'],
      ),
      fileUri: _readString(
        json['fileUri'] ?? json['file_uri'] ?? json['url'],
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
    this.price,
    required this.provider,
    required this.clinic,
    required this.description,
    this.followUpDate,
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
    final attachedDocumentsJson =
        (json['attached_documents'] ?? json['attachedDocuments'])
            as List<dynamic>?;

    return EventModel(
      id: _readString(json['id']),
      schema: _readInt(json['schema'], fallback: 1),
      petId: _readString(json['pet_id'] ?? json['petId']),
      ownerId: _readString(json['owner_id'] ?? json['ownerId']),
      title: _readString(json['title']),
      eventType: _readString(json['event_type'] ?? json['eventType']),
      date: _parseDate(json['date']),
      price: _readDouble(json['price']),
      provider: _readString(json['provider']),
      clinic: _readString(json['clinic']),
      description: _readString(json['description']),
      followUpDate: _parseNullableDate(
        json['follow_up_date'] ?? json['followUpDate'],
      ),
      attachedDocuments: attachedDocumentsJson == null
          ? const []
          : attachedDocumentsJson
              .map(_asStringDynamicMap)
              .map(EventDocumentModel.fromJson)
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
  if (value is DateTime) {
    return value;
  }

  if (value is! String || value.trim().isEmpty) {
    return DateTime(0);
  }

  return DateTime.tryParse(value) ?? DateTime(0);
}

DateTime? _parseNullableDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

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