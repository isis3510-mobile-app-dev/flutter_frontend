import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/models/smart_alert_model.dart';

class SmartAlertCard extends StatelessWidget {
  const SmartAlertCard({
    super.key,
    required this.suggestion,
    this.petName,
    this.showPetName = true,
    this.margin,
    this.onTap,
  });

  final SmartSuggestionModel suggestion;
  final String? petName;
  final bool showPetName;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SmartAlertPalette.fromType(
      suggestion.type,
      isDark: isDark,
    );
    final resolvedMargin =
        margin ??
        const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
          vertical: AppDimensions.spaceS,
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: resolvedMargin,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: palette.backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spaceXXS),
              child: Icon(palette.icon, size: 20, color: palette.textColor),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: TextStyle(
                      color: palette.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    suggestion.message,
                    style: TextStyle(
                      color: palette.textColor,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showPetName && (petName?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      petName!.trim(),
                      style: TextStyle(
                        color: palette.textColor.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartAlertPalette {
  const _SmartAlertPalette({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  factory _SmartAlertPalette.fromType(
    SmartSuggestionType type, {
    required bool isDark,
  }) {
    return switch (type) {
      SmartSuggestionType.danger => _SmartAlertPalette(
        backgroundColor: isDark
            ? AppColors.smartAlertDangerBgDark
            : AppColors.smartAlertDangerBg,
        textColor: isDark
            ? AppColors.smartAlertDangerTextDark
            : AppColors.smartAlertDangerText,
        icon: Icons.warning_rounded,
      ),
      SmartSuggestionType.warning => _SmartAlertPalette(
        backgroundColor: isDark
            ? AppColors.smartAlertWarningBgDark
            : AppColors.smartAlertWarningBg,
        textColor: isDark
            ? AppColors.smartAlertWarningTextDark
            : AppColors.smartAlertWarningText,
        icon: Icons.warning_amber_rounded,
      ),
      SmartSuggestionType.info => _SmartAlertPalette(
        backgroundColor: isDark
            ? AppColors.smartAlertInfoBgDark
            : AppColors.smartAlertInfoBg,
        textColor: isDark
            ? AppColors.smartAlertInfoTextDark
            : AppColors.smartAlertInfoText,
        icon: Icons.notifications_active_rounded,
      ),
    };
  }
}
