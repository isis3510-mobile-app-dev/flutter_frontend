import 'package:flutter_frontend/core/models/event_model.dart';

class AddEventArgs {
  const AddEventArgs({
    this.eventId,
    this.ownerId,
    this.petId,
    this.petName,
    this.eventName,
    this.eventType,
    this.dateTime,
    this.provider,
    this.clinic,
    this.description,
    this.price,
    this.followUpDate,
    this.attachedDocuments = const [],
  });

  final String? eventId;
  final String? ownerId;
  final String? petId;
  final String? petName;
  final String? eventName;
  final String? eventType;
  final DateTime? dateTime;
  final String? provider;
  final String? clinic;
  final String? description;
  final double? price;
  final DateTime? followUpDate;
  final List<EventDocumentModel> attachedDocuments;
}