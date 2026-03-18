import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.type,
    this.vaccination,
    this.pet,
    this.vaccineName
  });

  final String type;
  final PetVaccinationModel? vaccination;
  final PetModel? pet;
  final String? vaccineName;

  Future<void> _confirmAndDelete(BuildContext context) async {
    if (vaccination == null || pet == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete vaccine?'),
        content: const Text(
          'Are you sure you want to delete this vaccination record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.nfcCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final payload = <String, dynamic>{
        'vaccineId': vaccination!.vaccineId,
        'dateGiven': _formatDateForApi(vaccination!.dateGiven),
      };

      await PetService().deleteVaccination(
        petId: pet!.id,
        data: payload,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccine deleted successfully.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    }
  }

  void navigateToEditPage(BuildContext context) {
    if (type == 'vaccine') {
      Navigator.of(context).pushNamed(
        Routes.addVaccine,
        arguments: AddVaccineArgs(
          vaccineId: vaccination?.vaccineId,
          vaccineName: vaccineName,
          dateGiven: vaccination?.dateGiven,
          petId: pet?.id,
          petName: pet?.name,
          administeredBy: vaccination?.administeredBy,
        ),
      );
    } else if (type == 'event') {
      Navigator.of(context).pushNamed(Routes.addEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (appbarIcon, appbarTitle, lastCardTitle, lastCardEmpty) = switch (type) {
      'vaccine' => (
          Icons.vaccines_outlined,
          AppStrings.vaccineDetailsTitle,
          AppStrings.vaccineAttachedDocumentTitle,
          AppStrings.vaccineNoDocuments
        ),
      'event' => (
          Icons.event_note_outlined,
          AppStrings.eventDetailsTitle,
          AppStrings.eventNotesTitle,
          AppStrings.eventNoNotes
        ),
      _ => (
          Icons.info_outline,
          '',
          '',
          ''
        ),
    };
    
    final displayPetName = pet?.name.trim().isNotEmpty == true
        ? pet!.name.trim()
        : AppStrings.valueNotAvailable;
    final displayPetSpecies = pet?.species.trim().isNotEmpty == true
        ? pet!.species.trim()
        : '';
    final displaySubtitle = displayPetSpecies.isNotEmpty
        ? '$displayPetName - $displayPetSpecies'
        : displayPetName;

    final displayVaccineName = vaccineName?.trim().isNotEmpty == true
        ? vaccineName!.trim()
        : AppStrings.valueNotAvailable;
    final displayStatus = vaccination?.status.trim().isNotEmpty == true
        ? vaccination!.status.trim()
        : AppStrings.vaccineStatusCompleted;
    final displayDateGiven = vaccination?.dateGiven != null
        ? _formatDate(vaccination!.dateGiven)
        : AppStrings.valueNotAvailable;
    final displayNextDue = vaccination?.nextDueDate != null
        ? _formatDate(vaccination!.nextDueDate!)
        : AppStrings.hintNotProvided;
    final displayVet = vaccination?.administeredBy.trim().isNotEmpty == true
        ? vaccination!.administeredBy.trim()
        : pet?.defaultVet.trim().isNotEmpty == true
            ? pet!.defaultVet.trim()
            : AppStrings.valueNotAvailable;
    final displayClinic = vaccination?.clinicName.trim().isNotEmpty == true
        ? vaccination!.clinicName.trim()
        : AppStrings.valueNotAvailable;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        toolbarHeight: 80.0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(appbarIcon),
                SizedBox(width: 8),
                Text(appbarTitle),
              ]
            ),
            const SizedBox(height: 2),
            Text(
              displaySubtitle,
              style: TextStyle(
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type == 'vaccine')
                      Text(
                        displayVaccineName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.positiveBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.positiveText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
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
                title: AppStrings.vaccineTimelineTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppStrings.vaccineDateGivenLabel,
                      value: displayDateGiven,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: AppStrings.vaccineNextDueLabel,
                      value: displayNextDue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: AppStrings.providerInfoTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: AppStrings.veterinarianLabel,
                      value: displayVet,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: AppStrings.clinicLabel,
                      value: displayClinic,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: lastCardTitle,
                child: Text(
                  lastCardEmpty,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.secondary,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: FullWidthButton(
                    text: AppStrings.actionDelete,
                    onPressed: () => _confirmAndDelete(context),
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
                    text: AppStrings.actionEdit,
                    onPressed: () => navigateToEditPage(context),
                    icon: Icons.edit_outlined,
                    height: 52,
                  ),
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
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
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

String _formatDateForApi(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
class _InfoCard extends StatelessWidget {
  // ignore: unused_element_parameter
  const _InfoCard({this.title, required this.child, this.backgroundColor = AppColors.secondary});

  final String? title;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(color: AppColors.grey700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(color: AppColors.onSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
