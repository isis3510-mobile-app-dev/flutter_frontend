import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PetsSearchBar extends StatelessWidget {
  const PetsSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.petsSearchBarBackgroundDark
        : AppColors.petsSearchBarBackground;
    final iconColor = isDark
        ? AppColors.onSurfaceDark.withOpacity(0.72)
        : AppColors.petsSearchBarIcon;
    final placeholderColor = isDark
        ? AppColors.onSurfaceDark.withOpacity(0.58)
        : AppColors.petsSearchBarPlaceholder;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  autofocus: false,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  cursorColor: AppColors.bottomNavActive,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: 'Search pets...',
                    hintStyle: TextStyle(
                      color: placeholderColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
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
