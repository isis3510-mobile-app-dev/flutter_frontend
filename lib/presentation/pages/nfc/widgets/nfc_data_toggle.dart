import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.petFilterInactiveBorder,
          width: AppDimensions.strokeThin,
        ),
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
                    color: enabled ? AppColors.onSurface : AppColors.grey700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.grey700,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Checkbox(
            value: value,
            onChanged: enabled
                ? (newValue) {
                    if (newValue != null && onChanged != null) {
                      onChanged!(newValue);
                    }
                  }
                : null,
            activeColor: AppColors.primary,
            side: const BorderSide(
              color: AppColors.petFilterInactiveBorder,
              width: AppDimensions.strokeRegular,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}