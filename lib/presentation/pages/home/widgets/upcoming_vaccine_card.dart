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
    final textColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onSecondary;
    final subtextColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final timeLabel = switch (daysUntil) {
      < 0 => '${daysUntil.abs()}d',
      0 => 'Today',
      _ => '${daysUntil}d',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
          vertical: AppDimensions.spaceS,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: isDark ? Border.all(color: AppColors.grey700) : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.16)
                  : AppColors.shadowSoft,
              blurRadius: isDark ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.petCardQuickActionBgDark
                      : AppColors.primaryVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.iconVaccine,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      isDark ? AppColors.primaryVariant : AppColors.primary,
                      BlendMode.srcIn,
                    ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      '$petName • $date',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
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
                  color: isDark
                      ? AppColors.timeBackgroundDark
                      : AppColors.timeBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    color: isDark ? AppColors.timeTextDark : AppColors.timeText,
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
