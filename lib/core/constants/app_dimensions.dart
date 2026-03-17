/// Spacing and sizing constants used throughout the UI.
/// Using a consistent scale prevents arbitrary magic numbers in widgets
/// and keeps the design system coherent.
abstract class AppDimensions {
  // --- Spacing scale (in logical pixels) ---
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double spaceXXXL = 64.0;

  // --- Border radius ---
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // --- Icon sizes ---
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  static const double iconXXXL = 96.0;

  // --- Strokes ---
  static const double strokeThin = 1.0;
  static const double strokeMedium = 2.0;
  static const double strokeRegular = 1.5;

  // --- List item icon size ---
  static const double iconListItem = 40.0;

  // --- Typography ---
  static const double letterSpacingSection = 0.5;

  // --- Component specific ---
  static const double buttonHeight = 48.0;
  static const double buttonHeightL = 52.0;
  static const double segmentedControlHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double cardElevation = 2.0;

  // --- Horizontal page padding ---
  static const double pageHorizontalPadding = 16.0;
}
