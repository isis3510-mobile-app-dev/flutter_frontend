import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';

class PetPhotoPicker extends StatelessWidget {
  const PetPhotoPicker({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.addPetPhotoBackgroundDark
        : AppColors.addPetPhotoBackground;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(
                  color: AppColors.addPetPhotoAccent,
                  width: 1.6,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/featureIcons/camera.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      AppColors.addPetPhotoAccent,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    AppStrings.addPetPhotoTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.addPetPhotoAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            AppStrings.addPetPhotoHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
}
