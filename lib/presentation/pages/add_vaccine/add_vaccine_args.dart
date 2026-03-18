class AddVaccineArgs {
  const AddVaccineArgs({
    this.vaccinationId,
    this.vaccineId,
    this.vaccineName,
    this.dateGiven,
    this.petId,
    this.petName,
    this.administeredBy,
  });

  final String? vaccinationId;
  final String? vaccineId;
  final String? vaccineName;
  final DateTime? dateGiven;
  final String? petId;
  final String? petName;
  final String? administeredBy;
}
