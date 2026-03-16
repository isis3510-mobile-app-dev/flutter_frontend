import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Next upcoming vaccine card.
class UpcomingVaccineCard extends StatelessWidget {
  const UpcomingVaccineCard({
    super.key,
    required this.vaccineName,
    required this.petName,
    required this.date,
    required this.daysUntil,
    this.onTap,
  });

  final String vaccineName;
  final String petName;
  final String date;
  final int daysUntil;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final textColor = isDark ? AppColors.onBackgroundDark : AppColors.onSecondary;
    final subtextColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceL,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.petCardQuickActionBgDark
                      : AppColors.primaryVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.iconVaccine,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXT VACCINE',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      vaccineName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      '$petName • $date',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: AppDimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  '-${daysUntil}d',
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
