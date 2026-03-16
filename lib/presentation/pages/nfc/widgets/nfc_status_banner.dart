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
    final backgroundColor = isAttention
        ? AppColors.petStatusAttentionBg
        : AppColors.petStatusHealthyBg;
    final iconColor = isAttention
        ? AppColors.petStatusAttentionText
        : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
              style: const TextStyle(
                color: AppColors.onBackground,
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