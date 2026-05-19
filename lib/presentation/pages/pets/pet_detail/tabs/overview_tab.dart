import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/models/pet_model.dart';
import '../../../../../core/models/medicine_model.dart';
import '../../../../../core/services/app_image_cache_manager.dart';
import '../../../../../app/routes.dart';
import '../../../../../presentation/pages/medicine_detail/medicine_detail_args.dart';
import '../../models/pet_ui_model.dart';
import '../../../../../core/models/medicine_request.dart';
import '../../../../../core/services/medicine_service.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({
    super.key,
    required this.pet,
    required this.petDetails,
    required this.eventCount,
    required this.medicines,
    required this.onToggleLostMode,
    required this.onToggleNfc,
  });

  final PetUiModel pet;
  final PetModel? petDetails;
  final int eventCount;
  final List<MedicineModel> medicines;
  final VoidCallback onToggleLostMode;
  final VoidCallback onToggleNfc;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final MedicineService _medicineService = MedicineService();
  final Map<String, DateTime?> _givenStatus = {};
  @override
  void didUpdateWidget(covariant OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // reset local overrides when medicines list changes
    if (oldWidget.medicines != widget.medicines) {
      _givenStatus.clear();
    }
  }

  bool _isGivenToday(DateTime? lastAdministered) {
    final override = lastAdministered;
    if (override == null) return false;
    final now = DateTime.now();
    return override.year == now.year && override.month == now.month && override.day == now.day;
  }

  Future<void> _toggleGivenToday(MedicineModel med) async {
    final currently = _givenStatus.containsKey(med.id) ? _givenStatus[med.id] : med.lastAdministered;
    final isGiven = _isGivenToday(currently);
    final newValue = isGiven ? null : DateTime.now();

    setState(() => _givenStatus[med.id] = newValue);

    final request = MedicineRequest(
      petId: med.petId,
      medicineName: med.medicineName,
      administrationRoute: med.administrationRoute,
      dosageValue: med.dosageValue ?? 0.0,
      dosageUnit: med.dosageUnit,
      frequency: med.frequency,
      reminderEnabled: med.reminderEnabled,
      startDate: med.startDate,
      endDate: med.endDate,
      photoUrl: med.photoUrl,
      lastAdministered: newValue,
    );

    try {
      await _medicineService.updateMedicine(medicineId: med.id, request: request);
    } catch (_) {
      // revert on error
      setState(() {
        if (med.lastAdministered != null) {
          _givenStatus[med.id] = med.lastAdministered;
        } else {
          _givenStatus.remove(med.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update medicine status.')));
      }
    }
  }

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
                widget.pet.species,
                AppStrings.petDetailFieldBreed,
                widget.pet.breed,
              ),
              _InfoRow(
                AppStrings.petDetailFieldDob,
                _formatDate(widget.pet.birthDate),
                AppStrings.petDetailFieldAge,
                widget.pet.ageLabel,
              ),
              _InfoRow(
                AppStrings.petDetailFieldWeight,
                widget.pet.weightLabel,
                AppStrings.petDetailFieldColor,
                widget.pet.color,
              ),
              _InfoRow(
                AppStrings.petDetailFieldGender,
                widget.pet.gender,
                AppStrings.petDetailFieldMicrochip,
                AppStrings.valueNotAvailable,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _HealthSummaryCard(
            isDark: isDark,
            pet: widget.pet,
            petDetails: widget.petDetails,
            eventCount: widget.eventCount,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (widget.medicines.isNotEmpty) ...[
            _MedicinesTodaySection(
              medicines: widget.medicines,
              pet: widget.petDetails,
              onToggleGiven: _toggleGivenToday,
              givenStatus: _givenStatus,
            ),
            const SizedBox(height: AppDimensions.spaceM),
          ],
          _StatusRow(
            isNfcActive: widget.pet.isNfcSynced,
            isLost: widget.pet.status == 'lost',
            isDark: isDark,
            onToggleLostMode: widget.onToggleLostMode,
            onToggleNfc: widget.onToggleNfc,
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
    required this.eventCount,
  });

  final bool isDark;
  final PetUiModel pet;
  final PetModel? petDetails;
  final int eventCount;

  bool _isCompletedVaccination(PetVaccinationModel vaccination) {
    final status = vaccination.status.trim().toLowerCase();
    if (status == 'completed' || status == 'done' || status == 'applied') {
      return true;
    }

    if (status == 'overdue' || status == 'late' || status == 'expired') {
      return false;
    }

    final now = DateTime.now();
    if (vaccination.nextDueDate.year > 1 &&
        vaccination.nextDueDate.isBefore(now)) {
      return false;
    }
    if (vaccination.dateGiven.year > 1 && vaccination.dateGiven.isAfter(now)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? AppColors.petDetailHealthSummaryBgDark
        : AppColors.petDetailHealthSummaryBg;

    final vaccinations = petDetails?.vaccinations ?? const [];
    final totalVaccines = vaccinations.length;
    final completedVaccines = vaccinations
        .where(_isCompletedVaccination)
        .length;
    final vaccineMetric = totalVaccines == 0
        ? '0/0'
        : '$completedVaccines/$totalVaccines';
    final summaryTitleColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.grey900;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.pageHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.petDetailSectionHealthSummary.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: summaryTitleColor,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: _HealthMetricTile(
                  isDark: isDark,
                  icon: Icons.vaccines_outlined,
                  value: vaccineMetric,
                  label: 'Vaccines',
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _HealthMetricTile(
                  isDark: isDark,
                  icon: Icons.event_note_outlined,
                  value: '$eventCount',
                  label: 'Events',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicinesTodaySection extends StatelessWidget {
  const _MedicinesTodaySection({
    required this.medicines,
    required this.pet,
    required this.onToggleGiven,
    required this.givenStatus,
  });

  final List<MedicineModel> medicines;
  final PetModel? pet;
  final void Function(MedicineModel) onToggleGiven;
  final Map<String, DateTime?> givenStatus;

  bool _isForToday(MedicineModel medicine) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final start = medicine.startDate ?? DateTime(1900);
    final end = medicine.endDate ?? DateTime(3000);

    return !start.isAfter(todayEnd.subtract(const Duration(milliseconds: 1))) && !end.isBefore(todayStart);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;
    final todays = medicines.where(_isForToday).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.petDetailSectionMedicines.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: sectionTitleColor,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        if (todays.isEmpty)
          Text(AppStrings.petDetailMedicinesEmpty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey700)),
        for (final med in todays)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: med.photoUrl != null && med.photoUrl!.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildMedicineImage(med.photoUrl!),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.petFilterInactiveBorder),
                    ),
                    child: const Icon(Icons.medication_outlined, size: 28, color: AppColors.grey500),
                  ),
            title: Text(med.medicineName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${med.dosageValue ?? ''}${med.dosageUnit.isNotEmpty ? ' ${med.dosageUnit}' : ''} • ${med.administrationRoute}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (ctx) {
                  final last = givenStatus.containsKey(med.id) ? givenStatus[med.id] : med.lastAdministered;
                  final now = DateTime.now();
                  final isGiven = last != null && last.year == now.year && last.month == now.month && last.day == now.day;
                  return IconButton(
                    icon: Icon(isGiven ? Icons.check_circle : Icons.radio_button_unchecked, color: isGiven ? AppColors.primary : AppColors.grey500),
                    onPressed: () => onToggleGiven(med),
                    tooltip: isGiven ? 'Marked as given' : 'Mark as given',
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: pet == null
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            Routes.medicineDetail,
                            arguments: MedicineDetailArgs(medicine: med, pet: pet!),
                          ),
                ),
              ],
            ),
            onTap: null,
          ),
      ],
    );
  }
}

Widget _buildMedicineImage(String path) {
  final uri = Uri.tryParse(path);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return CachedNetworkImage(
      imageUrl: path,
      cacheManager: AppImageCacheManager.instance,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox(width: 48, height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) => const SizedBox(width: 48, height: 48, child: Icon(Icons.medication_outlined)),
    );
  }

  try {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication_outlined));
    }
  } catch (_) {}

  return const SizedBox(width: 48, height: 48, child: Icon(Icons.medication_outlined));
}

class _HealthMetricTile extends StatelessWidget {
  const _HealthMetricTile({
    required this.isDark,
    required this.icon,
    required this.value,
    required this.label,
  });

  final bool isDark;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tileColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.75);
    final iconColor = AppColors.bottomNavActive;
    final valueColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.bottomNavActive;
    final labelColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
