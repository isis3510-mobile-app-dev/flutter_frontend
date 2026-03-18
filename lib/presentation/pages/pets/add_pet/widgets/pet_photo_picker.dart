import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';

class PetPhotoPicker extends StatelessWidget {
  const PetPhotoPicker({super.key, this.onTap, this.imagePath});

  final VoidCallback? onTap;
  final String? imagePath;

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
              child: _buildPhoto(),
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

  Widget _buildPhoto() {
    final value = imagePath?.trim();
    if (value == null || value.isEmpty) {
      return Column(
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
          Builder(
            builder: (context) => Text(
              AppStrings.addPetPhotoTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.addPetPhotoAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final uri = Uri.tryParse(value);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: isNetwork
          ? Image.network(
              value,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Image.file(
              File(value),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
    );
  }
}
