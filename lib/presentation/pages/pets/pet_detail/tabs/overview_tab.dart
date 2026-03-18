import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/models/pet_model.dart';
import '../../models/pet_ui_model.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.pet,
    required this.petDetails,
    required this.onToggleLostMode,
    required this.onToggleNfc,
  });

  final PetUiModel pet;
  final PetModel? petDetails;
  final VoidCallback onToggleLostMode;
  final VoidCallback onToggleNfc;

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PetInfoCard(
            isDark: isDark,
            rows: [
              _InfoRow(
                AppStrings.petDetailFieldSpecies,
                pet.species,
                AppStrings.petDetailFieldBreed,
                pet.breed,
              ),
              _InfoRow(
                AppStrings.petDetailFieldDob,
                _formatDate(pet.birthDate),
                AppStrings.petDetailFieldAge,
                pet.ageLabel,
              ),
              _InfoRow(
                AppStrings.petDetailFieldWeight,
                pet.weightLabel,
                AppStrings.petDetailFieldColor,
                pet.color,
              ),
              _InfoRow(
                AppStrings.petDetailFieldGender,
                pet.gender,
                AppStrings.petDetailFieldMicrochip,
                AppStrings.valueNotAvailable,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _HealthSummaryCard(
            isDark: isDark,
            pet: pet,
            petDetails: petDetails,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _StatusRow(
            isNfcActive: pet.isNfcSynced,
            isLost: pet.status == 'lost',
            isDark: isDark,
            onToggleLostMode: onToggleLostMode,
            onToggleNfc: onToggleNfc,
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label1, this.value1, this.label2, this.value2);

  final String label1;
  final String value1;
  final String label2;
  final String value2;
}

class _PetInfoCard extends StatelessWidget {
  const _PetInfoCard({required this.isDark, required this.rows});

  final bool isDark;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? AppColors.petDetailInfoBackgroundDark
        : Colors.white;
    final titleColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              AppDimensions.pageHorizontalPadding,
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceS,
            ),
            child: Text(
              AppStrings.petDetailSectionPetInfo.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: titleColor,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      label: rows[i].label1,
                      value: rows[i].value1,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: _InfoCell(
                      label: rows[i].label2,
                      value: rows[i].value2,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.grey500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({
    required this.isDark,
    required this.pet,
    required this.petDetails,
  });

  final bool isDark;
  final PetUiModel pet;
  final PetModel? petDetails;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? AppColors.petDetailHealthSummaryBgDark
        : AppColors.petDetailHealthSummaryBg;

    final vaccinations = petDetails?.vaccinations ?? const [];
    final totalVaccines = vaccinations.length;
    final upcoming = vaccinations
        .where((v) => v.nextDueDate.isAfter(DateTime.now()))
        .toList(growable: false)
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final nextDue = upcoming.isEmpty ? null : upcoming.first;

    final allergy = pet.knownAllergies.trim().isEmpty
        ? AppStrings.valueNotAvailable
        : pet.knownAllergies;
    final vetName = pet.defaultVet.trim().isEmpty
        ? AppStrings.valueNotAvailable
        : pet.defaultVet;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        12,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.petDetailSectionHealthSummary.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.bottomNavActive,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vaccines recorded: $totalVaccines',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextDue != null
                ? 'Next due: ${_formatShortDate(nextDue.nextDueDate)}'
                : 'Next due: ${AppStrings.valueNotAvailable}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Known allergies: $allergy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Default vet: $vetName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.isNfcActive,
    required this.isLost,
    required this.isDark,
    required this.onToggleLostMode,
    required this.onToggleNfc,
  });

  final bool isNfcActive;
  final bool isLost;
  final bool isDark;
  final VoidCallback onToggleLostMode;
  final VoidCallback onToggleNfc;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.bottomNavTopBorderDark
        : AppColors.petFilterInactiveBorder;

    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            icon: Icons.location_on_outlined,
            label: isLost ? 'Found' : 'Lost Mode',
            isActive: isLost,
            borderColor: borderColor,
            isDark: isDark,
            onTap: onToggleLostMode,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _StatusPill(
            svgPath: 'assets/icons/featureIcons/nfc.svg',
            label: isNfcActive ? 'NFC Active' : 'NFC Inactive',
            isActive: isNfcActive,
            borderColor: borderColor,
            isDark: isDark,
            onTap: onToggleNfc,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    this.icon,
    this.svgPath,
    required this.label,
    required this.isActive,
    required this.borderColor,
    required this.isDark,
    this.onTap,
  });

  final IconData? icon;
  final String? svgPath;
  final String label;
  final bool isActive;
  final Color borderColor;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.bottomNavActive;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.grey700;
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath!,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              )
            else
              Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
