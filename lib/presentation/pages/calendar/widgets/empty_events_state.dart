import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

class EmptyEventsState extends StatelessWidget {
  const EmptyEventsState({super.key, this.onAddEvent});

  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onSurface;
    final subtitleColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppAssets.iconCalendar,
              width: AppDimensions.iconXXL,
              height: AppDimensions.iconXXL,
              colorFilter: ColorFilter.mode(
                isDark ? AppColors.grey500 : AppColors.grey300,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => Icon(
                Icons.event_busy_outlined,
                size: AppDimensions.iconXXL,
                color: isDark ? AppColors.grey500 : AppColors.grey300,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              AppStrings.calendarNoEventsForDay,
              style: TextStyle(
                color: titleColor,
                fontSize: AppDimensions.calendarEventTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            if (onAddEvent != null) ...[
              const SizedBox(height: AppDimensions.spaceL),
              FilledButton(
                onPressed: onAddEvent,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusCircle,
                    ),
                  ),
                ),
                child: const Text(AppStrings.semanticAddEventButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
