enum SmartSuggestionType { danger, warning, info }

SmartSuggestionType _parseSuggestionType(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return switch (normalized) {
    'danger' => SmartSuggestionType.danger,
    'warning' => SmartSuggestionType.warning,
    'info' => SmartSuggestionType.info,
    _ => SmartSuggestionType.info,
  };
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

Map<String, dynamic> _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return const <String, dynamic>{};
}

class SmartSuggestionModel {
  const SmartSuggestionModel({
    required this.type,
    required this.title,
    required this.message,
  });

  final SmartSuggestionType type;
  final String title;
  final String message;

  factory SmartSuggestionModel.fromJson(Map<String, dynamic> json) {
    return SmartSuggestionModel(
      type: _parseSuggestionType(json['type']),
      title: _readString(json['title']),
      message: _readString(json['message']),
    );
  }
}

class PetSmartSuggestionsModel {
  const PetSmartSuggestionsModel({
    required this.petId,
    required this.petName,
    required this.suggestions,
  });

  final String petId;
  final String petName;
  final List<SmartSuggestionModel> suggestions;

  factory PetSmartSuggestionsModel.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'];

    return PetSmartSuggestionsModel(
      petId: _readString(json['petId']),
      petName: _readString(json['petName']),
      suggestions: suggestionsJson is List
          ? suggestionsJson
                .map(_asStringDynamicMap)
                .map(SmartSuggestionModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  PetSmartSuggestionsModel copyWith({
    String? petId,
    String? petName,
    List<SmartSuggestionModel>? suggestions,
  }) {
    return PetSmartSuggestionsModel(
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class SmartAlertItem {
  const SmartAlertItem({
    required this.petId,
    required this.petName,
    required this.suggestion,
  });

  final String petId;
  final String petName;
  final SmartSuggestionModel suggestion;
}
