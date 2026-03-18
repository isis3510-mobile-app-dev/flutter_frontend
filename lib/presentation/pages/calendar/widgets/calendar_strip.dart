import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'date_item.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({
    super.key,
    required this.focusedMonth,
    required this.monthLabel,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime focusedMonth;
  final String monthLabel;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  static const List<String> _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackground;
    final weekdayColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final cardColor = isDark
        ? AppColors.petCardBackgroundDark
        : AppColors.secondary;
    final monthDates = _buildMonthDates(focusedMonth);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXS,
        AppDimensions.spaceXS,
        AppDimensions.spaceXS,
        AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.spaceXL,
                  minHeight: AppDimensions.spaceXL,
                ),
                splashRadius: AppDimensions.spaceM,
                icon: Icon(Icons.chevron_left, color: titleColor),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: AppDimensions.calendarMonthHeaderFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.spaceXL,
                  minHeight: AppDimensions.spaceXL,
                ),
                splashRadius: AppDimensions.spaceM,
                icon: Icon(Icons.chevron_right, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Row(
            children: _weekdayLabels
                .map((weekday) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: TextStyle(
                          color: weekdayColor,
                          fontSize: AppDimensions.calendarWeekdayFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          ...List.generate(monthDates.length ~/ 7, (weekIndex) {
            final weekStart = weekIndex * 7;
            final week = monthDates.sublist(weekStart, weekStart + 7);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXS),
              child: Row(
                children: week
                    .map((date) {
                      return Expanded(
                        child: DateItem(
                          date: date,
                          isSelected:
                              date != null && _isSameDay(date, selectedDate),
                          onTap: date == null
                              ? null
                              : () => onDateSelected(date),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DateTime?> _buildMonthDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final leadingEmptyCells = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final usedSlots = leadingEmptyCells + daysInMonth;
    final rowCount = (usedSlots / 7).ceil();
    final totalCells = rowCount * 7;

    return List.generate(totalCells, (index) {
      final dayNumber = index - leadingEmptyCells + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }

      return DateTime(month.year, month.month, dayNumber);
    }, growable: false);
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
