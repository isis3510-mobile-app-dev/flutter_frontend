import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../pets/models/pet_ui_model.dart';

/// Individual pet card displayed in the horizontal pets list.
/// Shows only pet image with status badge, name appears below.
class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
  });

  final PetUiModel pet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pet image with status badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.petCardQuickActionBgDark
                      : AppColors.petCardQuickActionBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  image: pet.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(pet.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: pet.photoUrl == null
                    ? Icon(
                        Icons.pets,
                        color: AppColors.primary,
                        size: AppDimensions.iconM,
                      )
                    : null,
              ),
              // Status badge
              _StatusBadge(status: pet.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          // Pet name
          Text(
            pet.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color _getBackgroundColor() {
    return switch (status) {
      'healthy' => AppColors.petStatusHealthyBg,
      'needs attention' => AppColors.petStatusAttentionBg,
      'lost' => AppColors.petStatusLostBg,
      _ => AppColors.petStatusHealthyBg,
    };
  }

  Color _getTextColor() {
    return switch (status) {
      'healthy' => AppColors.petStatusHealthyText,
      'needs attention' => AppColors.petStatusAttentionText,
      'lost' => AppColors.petStatusLostText,
      _ => AppColors.petStatusHealthyText,
    };
  }

  IconData _getIconData() {
    return switch (status) {
      'healthy' => Icons.check_circle,
      'needs attention' => Icons.warning_rounded,
      'lost' => Icons.not_listed_location,
      _ => Icons.check_circle,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          _getIconData(),
          size: 9,
          color: _getTextColor(),
        ),
      ),
    );
  }
}
