import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Overdue vaccines alert card.
class OverdueVaccinesCard extends StatelessWidget {
  const OverdueVaccinesCard({
    super.key,
    required this.overdueCount,
    required this.vaccineDetails,
    this.onTap,
  });

  final int overdueCount;
  final String vaccineDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: isDark? AppColors.overdueCardBackgroundDark : AppColors.overdueCardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: isDark? AppColors.overdueCardBorderDark : AppColors.overdueCardBorder,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                AppAssets.iconWarning,
                width: 44,
                height: 44,
                colorFilter: ColorFilter.mode(
                  isDark? AppColors.overdueCardBackgroundDark : AppColors.overdueCardBackground,
                  BlendMode.dst,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$overdueCount Overdue Vaccines',
                      style: TextStyle(
                        color: isDark? AppColors.overdueCardContentDark : AppColors.overdueCardContent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      vaccineDetails,
                      style: TextStyle(
                        color: isDark? AppColors.overdueCardContentDark : AppColors.overdueCardContent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark? AppColors.overdueCardContentDark : AppColors.overdueCardContent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
