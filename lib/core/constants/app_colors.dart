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
  static const Color background = Color(0xFFF6FCFB);
  static const Color surface = Color(0xFFF6FCFB);
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
  static const List<Color> welcomeFirstBackground = [
    Color(0xFF006A60),
    Color(0xFF00897B),
  ];
  static const List<Color> welcomeSecondBackground = [
    Color(0xFF4B607A),
    Color(0xFF37505F),
  ];
  static const List<Color> welcomeThirdBackground = [
    Color(0xFF7B3DC4),
    Color(0xFF5E2A9D),
  ];

  // --- Bottom navigation ---
  static const Color bottomNavActive = Color(0xFF006A60);
  static const Color bottomNavInactive = Color(0xFF3F4948);
  static const Color bottomNavBackground = Color(0xFFFFFFFF);
  static const Color bottomNavTopBorder = Color(0xFFE8EEEE);
  static const Color bottomNavInactiveDark = Color(0xFFC7C7C7);
  static const Color bottomNavBackgroundDark = Color(0xFF1C1B1F);
  static const Color bottomNavTopBorderDark = Color(0xFF2A2A2A);

  // --- Quick actions FAB ---
  static const Color quickFabBackground = Color(0xFF006A60);
  static const Color quickFabBackgroundDark = Color(0xFF0C8378);
  static const Color quickFabIcon = Color(0xFFFFFFFF);
  static const Color quickActionPillBackground = Color(0xFFFFFFFF);
  static const Color quickActionPillBackgroundDark = Color(0xFF2A2A2A);
  static const Color quickActionText = Color(0xFF1C1B1F);
  static const Color quickActionTextDark = Color(0xFFE6E1E5);
  static const Color quickActionIconBackground = Color(0xFF9FF2E2);
  static const Color quickActionIconBackgroundDark = Color(0xFF1D4F49);
  static const Color quickActionIconTint = Color(0xFF004D45);
  static const Color quickActionIconTintDark = Color(0xFF9FF2E2);
  static const Color quickActionShadow = Color(0x1A000000);
  static const Color addPetBannerText = Color(0xFF00201C);

  // --- Pet status pills ---
  static const Color petStatusHealthyText = Color(0xFF1B5E20);
  static const Color petStatusHealthyBg = Color(0xFFE8F5E9);
  static const Color petStatusAttentionText = Color(0xFFE65100);
  static const Color petStatusAttentionBg = Color(0xFFFFF8E1);

  // --- Pet filters ---
  static const Color petFilterInactiveBorder = Color(0xFFBEC9C8);

  // --- Add pet flow ---
  static const Color addPetStepInactiveLineDark = Color(0xFF4C4B51);
  static const Color addPetStepInactiveCircle = Color(0xFFF1F2F4);
  static const Color addPetStepInactiveCircleDark = Color(0xFF34333A);
  static const Color addPetChipBackgroundDark = Color(0xFF252429);
  static const Color addPetPhotoBackground = Color(0xFF9FF2E2);
  static const Color addPetPhotoBackgroundDark = Color(0xFF1E4F48);
  static const Color addPetPhotoAccent = Color(0xFF006A60);
  static const Color addPetReminderBackground = Color(0xFFF8F9FA);
  static const Color addPetReminderBackgroundDark = Color(0xFF2A2C31);

  // --- Pet card ---
  static const Color petCardBackground = Color(0xFFFFFFFF);
  static const Color petCardBackgroundDark = Color(0xFF2A2A2A);
  static const Color petCardQuickActionBg = Color(0xFFEEF8F7);
  static const Color petCardQuickActionBgDark = Color(0xFF1D4F49);
  static const Color petAgeIcon = Color(0xFFE63600);
  static const Color petQuickActionNfc = Color(0xFF3949AB);

  // --- Pets search bar ---
  static const Color petsSearchBarBackground = Color(0xFFEEFAF8);
  static const Color petsSearchBarBackgroundDark = Color(0xFF20312F);
  static const Color petsSearchBarIcon = Color(0xFF757575);
  static const Color petsSearchBarPlaceholder = Color(0xFF8E8E93);
}
