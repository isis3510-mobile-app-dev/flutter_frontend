import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/services/app_image_cache_manager.dart';

/// The profile header component displaying the user's avatar, name, and role.
/// Located at the top of the profile page.
class ProfileHeader extends StatelessWidget {
  final String initials;
  final String userName;
  final String userEmail;
  final int petCount;
  final String? localPhotoPath;
  final String? remotePhotoUrl;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.initials,
    required this.userName,
    required this.userEmail,
    required this.petCount,
    this.localPhotoPath,
    this.remotePhotoUrl,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerBgColor = AppColors.petDetailHeaderBg;
    final remoteUri = Uri.tryParse(remotePhotoUrl?.trim() ?? '');
    final hasRemotePhoto =
        remoteUri != null &&
        (remoteUri.scheme == 'http' || remoteUri.scheme == 'https');
    final hasLocalPhoto =
        localPhotoPath != null && localPhotoPath!.trim().isNotEmpty;
    final ImageProvider<Object>? imageProvider = hasRemotePhoto
      ? CachedNetworkImageProvider(
        remotePhotoUrl!.trim(),
        cacheManager: AppImageCacheManager.instance,
        )
        : hasLocalPhoto
        ? FileImage(File(localPhotoPath!))
        : null;

    return Container(
      color: headerBgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
            vertical: AppDimensions.spaceL,
          ),
          child: Row(
            children: [
              // Avatar with camera badge
              Stack(
                children: [
                  Container(
                    width: AppDimensions.iconXXL,
                    height: AppDimensions.iconXXL,
                    decoration: BoxDecoration(
                      color: AppColors.primaryVariant,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXL,
                      ),
                      image: imageProvider == null
                          ? null
                          : DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: imageProvider == null
                        ? Center(
                            child: Text(
                              initials,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: AppDimensions.iconL,
                      height: AppDimensions.iconL,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: headerBgColor,
                          width: AppDimensions.strokeMedium,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: AppColors.onPrimary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppDimensions.spaceL),
              // User info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spaceXS),
                    // User email
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppDimensions.spaceM),
                    // Pet count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceM,
                        vertical: AppDimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVariant,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: Text(
                        '$petCount ${AppStrings.nounPets}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
