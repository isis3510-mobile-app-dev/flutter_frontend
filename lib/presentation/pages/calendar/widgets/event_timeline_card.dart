import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class EventTimelineCard extends StatelessWidget {
  const EventTimelineCard({
    super.key,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.iconAssetPath,
    required this.cardColor,
    this.isLast = false,
    this.onTap,
  });

  final String timeLabel;
  final String title;
  final String subtitle;
  final String iconAssetPath;
  final Color cardColor;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onSurface;
    final subtitleColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimensions.calendarTimelineTimeColumnWidth,
          child: Column(
            children: [
              Text(
                timeLabel,
                style: TextStyle(
                  color: isDark
                      ? AppColors.onBackgroundDark
                      : AppColors.onBackground,
                  fontSize: AppDimensions.calendarEventTimeFontSize,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Container(
                width: AppDimensions.spaceS,
                height: AppDimensions.spaceS,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: AppDimensions.spaceS),
                Container(
                  width: AppDimensions.strokeThin,
                  height: AppDimensions.calendarTimelineLineHeight,
                  color: AppColors.grey300,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: AppDimensions.spaceS,
                      offset: Offset(0, AppDimensions.cardElevation),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: titleColor,
                                fontSize:
                                    AppDimensions.calendarEventTitleFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          SvgPicture.asset(
                            iconAssetPath,
                            width: AppDimensions.calendarEventIconSize,
                            height: AppDimensions.calendarEventIconSize,
                            colorFilter: ColorFilter.mode(
                              isDark
                                  ? AppColors.onBackgroundDark
                                  : AppColors.primary,
                              BlendMode.srcIn,
                            ),
                            placeholderBuilder: (_) => Icon(
                              Icons.event_note_outlined,
                              size: AppDimensions.calendarEventIconSize,
                              color: isDark
                                  ? AppColors.onBackgroundDark
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: AppDimensions.calendarEventSubtitleFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
