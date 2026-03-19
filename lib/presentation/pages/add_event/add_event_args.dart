import 'package:flutter_frontend/core/models/event_model.dart';

class AddEventArgs {
  const AddEventArgs({
    this.eventId,
    this.petId,
    this.petName,
    this.title,
    this.description,
    this.date,
    this.eventType,
    this.price,
    this.provider,
    this.clinic,
    this.followUpDate,
    this.attachedDocuments,
  });

  final String? eventId;
  final String? petId;
  final String? petName;
  final String? title;
  final String? description;
  final DateTime? date;
  final String? eventType;
  final double? price;
  final String? provider;
  final String? clinic;
  final DateTime? followUpDate;
  final List<EventDocumentModel>? attachedDocuments;
}
