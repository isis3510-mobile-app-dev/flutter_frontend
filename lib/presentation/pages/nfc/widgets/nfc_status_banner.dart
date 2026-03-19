import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class NfcStatusBanner extends StatelessWidget {
  const NfcStatusBanner({
    super.key,
    required this.message,
    this.isAttention = false,
  });

  final String message;
  final bool isAttention;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isAttention
        ? (isDark
              ? AppColors.negativeBackgroundDark
              : AppColors.petStatusAttentionBg)
        : (isDark
              ? AppColors.positiveBackgroundDark
              : AppColors.petStatusHealthyBg);
    final iconColor = isAttention
        ? (isDark
              ? AppColors.negativeTextDark
              : AppColors.petStatusAttentionText)
        : (isDark ? AppColors.positiveTextDark : AppColors.primary);
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: iconColor.withValues(alpha: isAttention ? 0.35 : 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: iconColor,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
