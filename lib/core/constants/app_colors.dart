import 'package:flutter/material.dart';

/// Centralized color palette for the entire app.
/// Never hardcode colors inside widgets — always reference from here.
/// This makes rebranding or theming changes straightforward.
abstract class AppColors {
  static const Color transparent = Colors.transparent;
  static const Color shadowSoft = Color(0x1A000000);

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
  static const Color positiveBackgroundDark = Color(0xFF1A3B38);
  static const Color negativeBackground = Color(0xFFFFEBEE);
  static const Color negativeBackgroundDark = Color(0xFF522421);
  static const Color positiveText = Color(0xFF2E7D32);
  static const Color positiveTextDark = Color.fromARGB(255, 66, 158, 106);
  static const Color negativeText = Color(0xFFC62828);
  static const Color infoText = Color(0xFF1565C0);
  static const Color infoBackground = Color(0xFFE3F2FD);

  // --- Vaccine status pills ---
  static const Color vaccineStatusCompletedText = positiveText;
  static const Color vaccineStatusCompletedBg = positiveBackground;
  static const Color vaccineStatusUpcomingText = infoText;
  static const Color vaccineStatusUpcomingBg = infoBackground;
  static const Color vaccineStatusOverdueText = negativeText;
  static const Color vaccineStatusOverdueBg = negativeBackground;
  static const Color negativeTextDark = Color(0xFFEF9A9A);

  // --- Neutral / grey scale ---
  static const Color grey100 = Color(0xFFF2F2F2);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF717171);
  static const Color grey900 = Color(0xFF414141);

  // --- Dark theme overrides ---
  static const Color backgroundDark = Color(0xFF1C1B1F);
  static const Color secondaryDark = Color(0xFF2A2A2A);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color onSecondaryDark = Color(0xFFE6E1E5);

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
  static const Color quickActionShadow = shadowSoft;
  static const Color addPetBannerText = Color(0xFF00201C);

  // --- Pet status pills ---
  static const Color petStatusHealthyText = Color(0xFF1B5E20);
  static const Color petStatusHealthyBg = Color(0xFFE8F5E9);
  static const Color petStatusAttentionText = Color(0xFFE65100);
  static const Color petStatusAttentionBg = Color(0xFFFFF8E1);
  static const Color petStatusLostText = Color(0xFFB3261E);
  static const Color petStatusLostBg = Color(0xFFFDECEC);

  // --- NFC actions ---
  static const Color nfcSmsActionBg = Color(0xFFDCEBFA);
  static const Color nfcSmsActionFg = Color(0xFF2563C9);

  // --- Pet filters ---
  static const Color petFilterInactiveBorder = Color(0xFFBEC9C8);
  static const Color petFilterInactiveBorderDark = Color(0xFF4C4B51);

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

  // --- Pet detail ---
  static const Color petDetailHeaderBg = Color(0xFF004D40);
  static const Color petDetailHealthSummaryBg = Color(0xFFE0F5F2);
  static const Color petDetailHealthSummaryBgDark = Color(0xFF1A3B38);
  static const Color petDetailInfoBackgroundDark = Color(0xFF1C2B29);

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

  // --- Overdue vaccines card ---
  static const Color overdueCardBackground = Color(0xFFFFF9EC);
  static const Color overdueCardBorder = Color(0xFFF4C542);
  static const Color overdueCardContent = Color(0xFFFF6A00);
  static const Color overdueCardBackgroundDark = Color(0xFF4B2E00);
  static const Color overdueCardBorderDark = Color(0xFF7B3D00);
  static const Color overdueCardContentDark = Color.fromARGB(
    255,
    208,
    179,
    150,
  );

  // --- Upcoming vaccine card ---
  static const Color timeBackground = Color(0xFFE3F2FD);
  static const Color timeText = Color(0xFF1976D2);
  static const Color timeBackgroundDark = Color.fromARGB(255, 29, 69, 79);
  static const Color timeTextDark = Color(0xFF9FF2E2);

  // --- Smart alerts ---
  static const Color smartAlertDangerBg = Color(0xFFFCE7EB);
  static const Color smartAlertDangerText = Color(0xFFC62828);
  static const Color smartAlertDangerBgDark = Color(0xFF4B2327);
  static const Color smartAlertDangerTextDark = Color(0xFFF8A7AF);

  static const Color smartAlertWarningBg = Color(0xFFFFF4E5);
  static const Color smartAlertWarningText = Color(0xFFE65100);
  static const Color smartAlertWarningBgDark = Color(0xFF4D3315);
  static const Color smartAlertWarningTextDark = Color(0xFFFFC38A);

  static const Color smartAlertInfoBg = Color(0xFFE7F1FB);
  static const Color smartAlertInfoText = Color(0xFF1565C0);
  static const Color smartAlertInfoBgDark = Color(0xFF1B334D);
  static const Color smartAlertInfoTextDark = Color(0xFF90CAF9);

  static const Color smartAlertVetBg = Color(0xFFE2F6F3);
  static const Color smartAlertVetText = Color(0xFF00695C);
  static const Color smartAlertVetBgDark = Color(0xFF173B37);
  static const Color smartAlertVetTextDark = Color(0xFF8CE7D8);
}
