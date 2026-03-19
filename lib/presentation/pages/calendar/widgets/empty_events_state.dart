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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 220;
        final iconSize = isCompactHeight
            ? AppDimensions.iconXL
            : AppDimensions.iconXXL;
        final topSpacing = isCompactHeight
            ? AppDimensions.spaceS
            : AppDimensions.spaceM;
        final buttonSpacing = isCompactHeight
            ? AppDimensions.spaceM
            : AppDimensions.spaceL;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pageHorizontalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppAssets.iconCalendar,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: ColorFilter.mode(
                      isDark ? AppColors.grey500 : AppColors.grey300,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (_) => Icon(
                      Icons.event_busy_outlined,
                      size: iconSize,
                      color: isDark ? AppColors.grey500 : AppColors.grey300,
                    ),
                  ),
                  SizedBox(height: topSpacing),
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
                    SizedBox(height: buttonSpacing),
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
          ),
        );
      },
    );
  }
}
