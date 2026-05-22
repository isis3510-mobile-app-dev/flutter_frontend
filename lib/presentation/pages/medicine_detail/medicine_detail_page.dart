import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/medicine_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/medicine_service.dart';
import 'package:flutter_frontend/presentation/pages/add_medicine/add_medicine_args.dart';
import 'package:flutter_frontend/presentation/pages/medicine_detail/medicine_detail_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class MedicineDetailPage extends StatefulWidget {
  const MedicineDetailPage({super.key, required this.args});

  final MedicineDetailArgs args;

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  final MedicineService _medicineService = MedicineService();

  late MedicineModel _medicine;
  late PetModel _pet;
  bool _isDeleting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _medicine = widget.args.medicine;
    _pet = widget.args.pet;
    _refreshMedicine();
  }

  Future<void> _refreshMedicine() async {
    final medicineId = _medicine.id.trim();
    if (medicineId.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedMedicine = await _medicineService.getMedicineById(medicineId);
      if (!mounted) {
        return;
      }
      setState(() => _medicine = updatedMedicine);
    } catch (_) {
      // Keep existing data if refresh fails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditPage() async {
    final result = await Navigator.of(context).pushNamed(
      Routes.addMedicine,
      arguments: AddMedicineArgs(
        medicineId: _medicine.id,
        petId: _pet.id,
        petName: _pet.name,
        medicineName: _medicine.medicineName,
        administrationRoute: _medicine.administrationRoute,
        dosageValue: _medicine.dosageValue,
        dosageUnit: _medicine.dosageUnit,
        frequency: _medicine.frequency,
        startDate: _medicine.startDate,
        endDate: _medicine.endDate,
        photoUrl: _medicine.photoUrl,
        reminderEnabled: _medicine.reminderEnabled,
        lastAdministered: _medicine.lastAdministered,
      ),
    );

    if (result == true) {
      await _refreshMedicine();
    }
  }

  Future<void> _confirmAndDelete() async {
    final medicineName = _medicine.medicineName.trim().isNotEmpty
        ? _medicine.medicineName.trim()
        : AppStrings.valueNotAvailable;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Are you sure you want to delete $medicineName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.nfcCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await _medicineService.deleteMedicine(_medicine.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final medicineName = _medicine.medicineName.trim().isNotEmpty
        ? _medicine.medicineName.trim()
        : AppStrings.valueNotAvailable;
    final petName = _pet.name.trim().isNotEmpty
        ? _pet.name.trim()
        : AppStrings.valueNotAvailable;
    final petSpecies = _pet.species.trim().isNotEmpty ? _pet.species.trim() : '';
    final subtitle = petSpecies.isNotEmpty ? '$petName - $petSpecies' : petName;
    final route = _medicine.administrationRoute.trim().isNotEmpty
        ? _medicine.administrationRoute.trim()
        : AppStrings.valueNotAvailable;
    final photoUrl = _medicine.photoUrl?.trim() ?? '';
    final dosageValue = _medicine.dosageValue == null
        ? AppStrings.hintNotProvided
        : '${_medicine.dosageValue!.toStringAsFixed(_medicine.dosageValue! % 1 == 0 ? 0 : 2)} ${_medicine.dosageUnit.trim().isNotEmpty ? _medicine.dosageUnit.trim() : ''}'.trim();
    final frequency = _medicine.frequency > 0
        ? '${_medicine.frequency} per day'
        : AppStrings.hintNotProvided;
    final startDate = _isValidDate(_medicine.startDate)
        ? _formatDate(_medicine.startDate!)
        : AppStrings.valueNotAvailable;
    final endDate = _isValidDate(_medicine.endDate)
        ? _formatDate(_medicine.endDate!)
        : AppStrings.hintNotProvided;
    final lastAdministered = _isValidDate(_medicine.lastAdministered)
        ? _formatDate(_medicine.lastAdministered!)
        : AppStrings.hintNotProvided;
    final reminderText = _medicine.reminderEnabled
        ? AppStrings.stateEnabled
        : AppStrings.stateDisabled;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        toolbarHeight: 80,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication),
                SizedBox(width: 8),
                Text('Medicine Details'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey100,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              if (_isLoading) const SizedBox(height: 12),
              _InfoCard(
                backgroundColor:
                    isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: isDark
                            ? AppColors.quickActionIconBackgroundDark
                            : AppColors.quickActionIconBackground,
                        child: photoUrl.isNotEmpty
                            ? _buildPhoto(photoUrl, isDark)
                            : Icon(
                                Icons.image_outlined,
                                size: 26,
                                color: isDark
                                    ? AppColors.quickActionIconTintDark
                                    : AppColors.quickActionIconTint,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.onSurfaceDark
                                  : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.positiveBackgroundDark
                                  : AppColors.positiveBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _medicine.reminderEnabled
                                      ? Icons.notifications_active_outlined
                                      : Icons.notifications_off_outlined,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.positiveTextDark
                                      : AppColors.positiveText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reminderText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.positiveTextDark
                                        : AppColors.positiveText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor:
                    isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: 'Schedule',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.pets_outlined,
                      label: AppStrings.labelPetName,
                      value: petName,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.route_outlined,
                      label: 'Administration Route',
                      value: route,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: '${AppStrings.labelDate} start',
                      value: startDate,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: '${AppStrings.labelDate} end',
                      value: endDate,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor:
                    isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: 'Dosage',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.science_outlined,
                      label: 'Dosage',
                      value: dosageValue,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Frequency',
                      value: frequency,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'Last Administered',
                      value: lastAdministered,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: isDark ? AppColors.secondaryDark : AppColors.secondary,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: FullWidthButton(
                    text: AppStrings.actionDelete,
                    onPressed: _isDeleting ? () {} : _confirmAndDelete,
                    backgroundColor: Colors.transparent,
                    borderColor: AppColors.error,
                    textColor: AppColors.error,
                    splashColor: AppColors.negativeText,
                    icon: Icons.delete_outline,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FullWidthButton(
                    backgroundColor: AppColors.primary,
                    text: AppStrings.actionEdit,
                    onPressed: _navigateToEditPage,
                    icon: Icons.edit_outlined,
                    height: 52,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String photoUrl, bool isDark) {
    final uri = Uri.tryParse(photoUrl);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isNetwork) {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.broken_image_outlined,
          size: 26,
          color: isDark
              ? AppColors.quickActionIconTintDark
              : AppColors.quickActionIconTint,
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.backgroundColor,
    required this.borderColor,
    this.title,
    required this.child,
  });

  final Color backgroundColor;
  final Color borderColor;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.onSurfaceDark
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.grey500 : AppColors.grey700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isValidDate(DateTime? date) {
  return date != null && date.year > 1900;
}

String _formatDate(DateTime date) {
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
