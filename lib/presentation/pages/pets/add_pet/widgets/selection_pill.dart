import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class SelectionPill extends StatelessWidget {
  const SelectionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.expand = false,
    this.minWidth = 102,
    this.horizontalPadding = 14,
    this.verticalPadding = 10,
    this.iconSpacing = 6,
    this.labelStyle,
  });

  final String label;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool expand;
  final double minWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSpacing;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pill = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bottomNavActive
              : (isDark ? AppColors.addPetChipBackgroundDark : Colors.white),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          border: Border.all(
            color: isSelected
                ? AppColors.bottomNavActive
                : AppColors.petFilterInactiveBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: iconSpacing),
            Text(
              label,
              style:
                  labelStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.grey700),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );

    if (expand) {
      return Expanded(child: pill);
    }

    return pill;
  }
}
