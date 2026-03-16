import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Individual event card displayed in the upcoming events list.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.eventName,
    required this.petName,
    required this.date,
    required this.hasReminder,
    this.isGrouped = false,
    this.onTap,
  });

  final String eventName;
  final String petName;
  final String date;
  final bool hasReminder;
  final bool isGrouped;
  final VoidCallback? onTap;

  String get _getEventIconPath {
    if (eventName.toLowerCase().contains('vaccine')) {
      return AppAssets.iconVaccine;
    } else if (eventName.toLowerCase().contains('vet check') ||
        eventName.toLowerCase().contains('checkup')) {
      return AppAssets.iconVetCheck;
    }
    return AppAssets.iconVetCheck;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;
    final subtextColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;

    final eventContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      child: Row(
        children: [
          // Event Icon
          SvgPicture.asset(
            _getEventIconPath,
            width: 38,
            height: 38,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  '$petName • $date',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Reminder Badge
          if (hasReminder)
            Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spaceM),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: AppDimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.positiveBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 12,
                      color: AppColors.positiveText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder on',
                      style: TextStyle(
                        color: AppColors.positiveText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (isGrouped) {
      return GestureDetector(
        onTap: onTap,
        child: eventContent,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: borderColor,
            width: AppDimensions.strokeThin,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: eventContent,
      ),
    );
  }
}
