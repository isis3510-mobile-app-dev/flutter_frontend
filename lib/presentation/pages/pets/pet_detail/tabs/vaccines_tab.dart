import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/models/pet_model.dart';
import '../../models/pet_ui_model.dart';

class VaccinesTab extends StatelessWidget {
  const VaccinesTab({
    super.key,
    required this.pet,
    required this.vaccinations,
  });

  final PetUiModel pet;
  final List<PetVaccinationModel> vaccinations;

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
              Icons.vaccines_outlined,
              size: 44,
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey500,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'TODO: Vaccines integration pending.',
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
