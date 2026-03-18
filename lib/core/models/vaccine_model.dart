class VaccineModel {
  const VaccineModel({
    required this.id,
    required this.schema,
    required this.name,
    this.species = const [],
    this.productName = '',
    this.manufacturer = '',
    this.intervalDays = 0,
    this.description = '',
  });

  final String id;
  final String schema;
  final String name;
  final List<String> species;
  final String productName;
  final String manufacturer;
  final int intervalDays;
  final String description;

  factory VaccineModel.fromJson(Map<String, dynamic> json) {
    final speciesJson = json['species'] as List<dynamic>?;

    return VaccineModel(
      id: _readString(json['id']),
      schema: _readString(json['schema']),
      name: _readString(json['name']),
      species: speciesJson == null
          ? const []
          : speciesJson.map((item) => item.toString()).toList(growable: false),
      productName: _readString(json['productName']),
      manufacturer: _readString(json['manufacturer']),
      intervalDays: _readInt(json['intervalDays'], fallback: 0),
      description: _readString(json['description']),
    );
  }

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