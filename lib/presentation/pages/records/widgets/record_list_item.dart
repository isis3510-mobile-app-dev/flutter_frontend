import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecordListItem extends StatelessWidget {
  const RecordListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.iconAssetPath,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String? iconAssetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark? AppColors.secondaryDark : AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark? AppColors.grey900 : AppColors.grey100,
            blurRadius: 4,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: (iconAssetPath != null && iconAssetPath!.isNotEmpty)
                      ? iconAssetPath!.toLowerCase().endsWith('.svg')
                          ? SvgPicture.asset(
                              iconAssetPath!,
                              width: 20,
                              height: 20,
                              placeholderBuilder: (_) => Icon(
                                icon,
                                color: iconColor,
                                size: 20,
                              ),
                            )
                          : Image.asset(
                              iconAssetPath!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                icon,
                                color: iconColor,
                                size: 20,
                              ),
                            )
                      : Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark? AppColors.onSurfaceDark : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark? AppColors.onSurfaceDark : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark? AppColors.grey500 : AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark? AppColors.grey500 : AppColors.grey700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
