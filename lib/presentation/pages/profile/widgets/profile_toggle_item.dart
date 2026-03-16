import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';

/// A reusable toggle item for preference settings in the profile page.
/// Displays an icon, title, optional subtitle, and a Material 3 Switch.
class ProfileToggleItem extends StatelessWidget {
  final IconData? icon;
  final String? imageAssetPath;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileToggleItem({
    Key? key,
    this.icon,
    this.imageAssetPath,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
        vertical: AppDimensions.spaceM,
      ),
      child: Row(
        children: [
          // Icon - no background box
          if (imageAssetPath != null)
            Image.asset(
              imageAssetPath!,
              width: AppDimensions.iconL + 8,
              height: AppDimensions.iconL + 8,
            )
          else if (icon != null)
            Icon(
              icon,
              color: defaultIconColor,
              size: AppDimensions.iconL + 8,
            ),
          SizedBox(width: AppDimensions.spaceL),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spaceXS),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey500,
                            fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Material 3 Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
