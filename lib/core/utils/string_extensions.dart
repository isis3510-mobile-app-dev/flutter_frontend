/// Utility extensions on the String type.
/// Add any string helpers you find yourself repeating across the codebase.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  /// Example: 'hello world' → 'Hello world'
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of every word.
  /// Example: 'hello world' → 'Hello World'
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Returns true if the string is a valid email address.
  bool get isValidEmail {
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(this);
  }

  /// Returns true if the string contains only digits.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Truncates the string to [maxLength] and appends '...' if needed.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// Utility extensions on nullable String.
extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns the string or a fallback value if null/empty.
  String orDefault(String fallback) {
    return isNullOrEmpty ? fallback : this!;
  }
}