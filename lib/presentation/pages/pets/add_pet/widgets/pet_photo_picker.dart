import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/services/app_image_cache_manager.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';

class PetPhotoPicker extends StatelessWidget {
  const PetPhotoPicker({
    super.key,
    this.onTap,
    this.onRemovePhoto,
    this.imagePath,
  });

  final VoidCallback? onTap;
  final VoidCallback? onRemovePhoto;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.addPetPhotoBackgroundDark
        : AppColors.addPetPhotoBackground;
    final hintColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.82)
        : AppColors.grey700;
    final actionBorderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final actionBackground = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;

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
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.14)
                        : AppColors.shadowSoft,
                    blurRadius: isDark ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildPhoto(context),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          if (imagePath?.trim().isNotEmpty == true) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppDimensions.spaceS,
              runSpacing: AppDimensions.spaceS,
              children: [
                OutlinedButton.icon(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: actionBackground,
                    side: BorderSide(color: actionBorderColor),
                    foregroundColor: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(AppStrings.profileChangePhoto),
                ),
                TextButton(
                  onPressed: onRemovePhoto,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.negativeTextDark
                        : AppColors.error,
                  ),
                  child: const Text(AppStrings.profileRemovePhoto),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceS),
          ],
          Text(
            AppStrings.addPetPhotoHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final value = imagePath?.trim();
    if (value == null || value.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accentColor = isDark
          ? AppColors.primaryVariant
          : AppColors.addPetPhotoAccent;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/featureIcons/camera.svg',
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            AppStrings.addPetPhotoTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final uri = Uri.tryParse(value);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: isNetwork
          ? CachedNetworkImage(
              imageUrl: value,
              cacheManager: AppImageCacheManager.instance,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, _) => const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              ),
              errorWidget: (_, _, _) => const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              ),
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
