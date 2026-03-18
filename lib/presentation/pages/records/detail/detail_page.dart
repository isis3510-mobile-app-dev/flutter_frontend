import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class DetailPage extends StatefulWidget {
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

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final PetService _petService = PetService();
  final VaccineService _vaccineService = VaccineService();

  PetVaccinationModel? _vaccination;
  PetModel? _pet;
  String? _vaccineName;

  @override
  void initState() {
    super.initState();
    _vaccination = widget.vaccination;
    _pet = widget.pet;
    _vaccineName = widget.vaccineName;
  }

  Future<void> _refreshVaccination() async {
    if (widget.type != 'vaccine' ||
        _pet == null ||
        _vaccination == null ||
        _vaccination!.id.trim().isEmpty) {
      return;
    }

    try {
      final updatedVaccination = await _petService.getVaccination(
        petId: _pet!.id,
        vaccinationId: _vaccination!.id,
      );
      final updatedVaccineInfo = await _vaccineService.getVaccineById(
        updatedVaccination.vaccineId,
      );

      if (!mounted) return;
      setState(() {
        _vaccination = updatedVaccination;
        _vaccineName = updatedVaccineInfo.name;
      });
    } catch (_) {
      // Keep existing data if refresh fails.
    }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    if (_vaccination == null || _pet == null) {
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
      await PetService().deleteVaccination(
        petId: _pet!.id,
        vaccinationId: _vaccination!.id,
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

  Future<void> navigateToEditPage(BuildContext context) async {
    if (widget.type == 'vaccine') {
      final result = await Navigator.of(context).pushNamed(
        Routes.addVaccine,
        arguments: AddVaccineArgs(
          vaccinationId: _vaccination?.id,
          vaccineId: _vaccination?.vaccineId,
          vaccineName: _vaccineName,
          dateGiven: _vaccination?.dateGiven,
          petId: _pet?.id,
          petName: _pet?.name,
          administeredBy: _vaccination?.administeredBy,
        ),
      );
      if (result == true) {
        await _refreshVaccination();
      }
    } else if (widget.type == 'event') {
      Navigator.of(context).pushNamed(Routes.addEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (appbarIcon, appbarTitle, lastCardTitle, lastCardEmpty) =
        switch (widget.type) {
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
    
    final displayPetName = _pet?.name.trim().isNotEmpty == true
        ? _pet!.name.trim()
        : AppStrings.valueNotAvailable;
    final displayPetSpecies = _pet?.species.trim().isNotEmpty == true
        ? _pet!.species.trim()
        : '';
    final displaySubtitle = displayPetSpecies.isNotEmpty
        ? '$displayPetName - $displayPetSpecies'
        : displayPetName;

    final displayVaccineName = _vaccineName?.trim().isNotEmpty == true
        ? _vaccineName!.trim()
        : AppStrings.valueNotAvailable;
    final displayStatus = _vaccination?.status.trim().isNotEmpty == true
        ? _vaccination!.status.trim()
        : AppStrings.vaccineStatusCompleted;
    final displayDateGiven = _vaccination?.dateGiven != null
        ? _formatDate(_vaccination!.dateGiven)
        : AppStrings.valueNotAvailable;
    final displayNextDue = _vaccination?.nextDueDate != null
        ? _formatDate(_vaccination!.nextDueDate)
        : AppStrings.hintNotProvided;
    final displayVet = _vaccination?.administeredBy.trim().isNotEmpty == true
        ? _vaccination!.administeredBy.trim()
        : _pet?.defaultVet.trim().isNotEmpty == true
            ? _pet!.defaultVet.trim()
            : AppStrings.valueNotAvailable;
    final displayClinic = _vaccination?.clinicName.trim().isNotEmpty == true
        ? _vaccination!.clinicName.trim()
        : AppStrings.valueNotAvailable;

    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
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
                backgroundColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.type == 'vaccine')
                      Text(
                        displayVaccineName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.positiveBackgroundDark : AppColors.positiveBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: isDark? AppColors.positiveTextDark : AppColors.positiveText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark? AppColors.positiveTextDark : AppColors.positiveText,
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
                backgroundColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: AppStrings.vaccineTimelineTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppStrings.vaccineDateGivenLabel,
                      value: displayDateGiven,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: AppStrings.vaccineNextDueLabel,
                      value: displayNextDue,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: AppStrings.providerInfoTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: AppStrings.veterinarianLabel,
                      value: displayVet,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: AppStrings.clinicLabel,
                      value: displayClinic,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
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
                    backgroundColor: AppColors.primary,
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

class _InfoCard extends StatelessWidget {
  // ignore: unused_element_parameter
  const _InfoCard({this.title, required this.child, required this.backgroundColor, required this.borderColor});

  final String? title;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

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
                style: context.textTheme.bodySmall?.copyWith(color: 
                isDark? AppColors.grey300 : AppColors.grey700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(color: 
                isDark? AppColors.onSecondaryDark : AppColors.onSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
