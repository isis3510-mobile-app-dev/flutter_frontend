import 'package:flutter/material.dart';

/// Centralized color palette for the entire app.
/// Never hardcode colors inside widgets — always reference from here.
/// This makes rebranding or theming changes straightforward.
abstract class AppColors {
  // --- Primary palette ---
  static const Color primary = Color(0xFF006A60);
  static const Color primaryVariant = Color(0xFF9FF2E2);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Secondary palette ---
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color.fromARGB(255, 64, 65, 65);

  // --- Background & surface ---
  static const Color background = Color(0xFFF6FCFB);
  static const Color surface = Color(0xFFF6FCFB);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF3F4948);

  // --- Semantic colors ---
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF386A20);
  static const Color warning = Color(0xFFE65100);
  static const Color positiveBackground = Color(0xFFE8F5E9);
  static const Color negativeBackground = Color(0xFFFFEBEE);
  static const Color positiveText = Color(0xFF2E7D32);
  static const Color negativeText = Color(0xFFC62828);

  // --- Neutral / grey scale ---
  static const Color grey100 = Color(0xFFF2F2F2);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF717171);
  static const Color grey900 = Color(0xFF414141);

  // --- Dark theme overrides ---
  static const Color backgroundDark = Color(0xFF1C1B1F);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // --- Welcome pages colors ---
  static const Color welcomeFirstBackground = Color(0xFF01796D);
  static const Color welcomeSecondBackground = Color(0xFF41586D);
  static const Color welcomeThirdBackground = Color(0xFF6B33AF);
}