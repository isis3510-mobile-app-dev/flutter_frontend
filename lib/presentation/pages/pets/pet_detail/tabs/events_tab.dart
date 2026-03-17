import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../models/pet_ui_model.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({super.key, required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 44,
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey500,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'TODO: Events integration pending.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              AppStrings.featureUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
