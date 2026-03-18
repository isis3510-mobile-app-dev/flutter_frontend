import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class DateItem extends StatelessWidget {
  const DateItem({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime? date;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayNumberColor = isSelected
        ? AppColors.onPrimary
        : (isDark ? AppColors.onBackgroundDark : AppColors.onBackground);

    if (date == null) {
      return SizedBox(height: AppDimensions.calendarMonthDateCellSize);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: AppDimensions.calendarMonthDateCellSize,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isSelected
                ? AppDimensions.calendarMonthSelectedDayWidth
                : AppDimensions.calendarMonthDateCellSize,
            height: AppDimensions.calendarMonthDateCellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: AppDimensions.spaceS,
                        offset: Offset(0, AppDimensions.cardElevation),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${date!.day}',
              style: TextStyle(
                color: dayNumberColor,
                fontSize: AppDimensions.calendarMonthDayNumberFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
