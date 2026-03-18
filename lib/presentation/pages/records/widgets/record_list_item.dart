import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class RecordListItem extends StatelessWidget {
  const RecordListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.statusLabel,
    this.statusBackgroundColor,
    this.statusTextColor,
    this.showTrailingChevron = true,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String? statusLabel;
  final Color? statusBackgroundColor;
  final Color? statusTextColor;
  final bool showTrailingChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.grey100,
            blurRadius: 12,
            offset: Offset(0, 4),
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
                child: Icon(icon, color: iconColor, size: 20),
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
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null && statusLabel!.trim().isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor ?? AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: statusTextColor ?? AppColors.grey700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (showTrailingChevron)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
