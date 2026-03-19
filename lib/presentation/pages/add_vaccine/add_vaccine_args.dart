import 'package:flutter_frontend/core/models/pet_model.dart';

class AddVaccineArgs {
  const AddVaccineArgs({
    this.vaccinationId,
    this.vaccineId,
    this.vaccineName,
    this.dateGiven,
    this.petId,
    this.petName,
    this.administeredBy,
    this.attachedDocuments,
  });

  final String? vaccinationId;
  final String? vaccineId;
  final String? vaccineName;
  final DateTime? dateGiven;
  final String? petId;
  final String? petName;
  final String? administeredBy;
  final List<PetDocumentModel>? attachedDocuments;
}
