import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_toggle_switch.dart';

class NfcDataToggle extends StatelessWidget {
  const NfcDataToggle({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.enabled = true,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.surface;
    final borderColor = isDark
        ? AppColors.petFilterInactiveBorderDark
        : AppColors.petFilterInactiveBorder;
    final titleColor = enabled
        ? (isDark ? AppColors.onSurfaceDark : AppColors.onSurface)
        : (isDark ? AppColors.grey500 : AppColors.grey700);
    final subtitleColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: borderColor, width: AppDimensions.strokeThin),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          AppToggleSwitch(value: value, enabled: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
