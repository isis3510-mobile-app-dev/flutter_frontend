import 'package:flutter/material.dart';

/// Centralized color palette for the entire app.
/// Never hardcode colors inside widgets — always reference from here.
/// This makes rebranding or theming changes straightforward.
abstract class AppColors {
  // --- Primary palette ---
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryVariant = Color(0xFF4F378B);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Secondary palette ---
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // --- Background & surface ---
  static const Color background = Color(0xFFFFFBFE);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);

  // --- Semantic colors ---
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF386A20);
  static const Color warning = Color(0xFFE65100);

  // --- Neutral / grey scale ---
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey900 = Color(0xFF212121);

  // --- Dark theme overrides ---
  static const Color backgroundDark = Color(0xFF1C1B1F);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // --- Welcome pages colors ---
  static const List<Color> welcomeFirstBackground = [Color(0xFF006A60), Color(0xFF00897B)];
  static const List<Color> welcomeSecondBackground = [Color(0xFF4B607A), Color(0xFF37505F)];
  static const List<Color> welcomeThirdBackground = [Color(0xFF7B3DC4), Color(0xFF5E2A9D)];
}