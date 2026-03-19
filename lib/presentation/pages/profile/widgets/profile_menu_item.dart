import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';

/// A reusable menu item for the profile page.
/// Displays an icon, title, and optional subtitle with a tap action.
class ProfileMenuItem extends StatelessWidget {
  final bool isDark;
  final IconData? icon;
  final String? imageAssetPath;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const ProfileMenuItem({
    super.key,
    this.icon,
    this.imageAssetPath,
    required this.title,
    required this.isDark,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                  width: AppDimensions.iconListItem,
                  height: AppDimensions.iconListItem,
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: AppDimensions.iconListItem,
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
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppDimensions.spaceXS,
                        ),
                        child: Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Chevron icon for navigation
              if (!isDestructive && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.grey300,
                  size: AppDimensions.iconM,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
