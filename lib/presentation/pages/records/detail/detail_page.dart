import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/add_event/add_event_args.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.type,
    this.vaccination,
    this.pet,
    this.vaccineName,
    this.event,
  });

  final String type;
  final PetVaccinationModel? vaccination;
  final PetModel? pet;
  final String? vaccineName;
  final EventModel? event;

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
    if (type == 'vaccine' && (vaccination == null || pet == null)) {
      return;
    }

    if (type == 'event' && event == null) {
      return;
    }

    final isEvent = type == 'event';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEvent ? 'Delete event?' : 'Delete vaccine?'),
        content: Text(
          isEvent
              ? 'Are you sure you want to delete this event record?'
              : 'Are you sure you want to delete this vaccination record?',
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
      if (isEvent) {
        await EventService().deleteEvent(event!.id);
      } else {
        await PetService().deleteVaccination(
          petId: pet!.id,
          vaccinationId: vaccination!.id,
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEvent
                ? 'Event deleted successfully.'
                : 'Vaccine deleted successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    }
  }

  Future<void> navigateToEditPage(BuildContext context) async {
    if (type == 'vaccine') {
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
    } else if (type == 'event') {
      final result = await Navigator.of(context).pushNamed(
        Routes.addEvent,
        arguments: AddEventArgs(
          eventId: event?.id,
          petId: pet?.id,
          petName: pet?.name,
          title: event?.title,
          description: event?.description,
          date: event?.date,
          eventType: event?.eventType,
          price: event?.price,
          provider: event?.provider,
          clinic: event?.clinic,
          followUpDate: event?.followUpDate,
        ),
      );

      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
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
    
    final isVaccine = type == 'vaccine';
    final isEvent = type == 'event';

    final appbarIcon = isVaccine
        ? Icons.vaccines_outlined
        : isEvent
            ? Icons.event_note_outlined
            : Icons.info_outline;
    final appbarTitle = isVaccine
        ? AppStrings.vaccineDetailsTitle
        : isEvent
            ? AppStrings.eventDetailsTitle
            : '';

    final displayPetName = pet?.name.trim().isNotEmpty == true
        ? pet!.name.trim()
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
    final displayVaccineStatus = vaccination?.status.trim().isNotEmpty == true
        ? vaccination!.status.trim()
        : AppStrings.vaccineStatusCompleted;
    final displayDateGiven = _isValidDate(vaccination?.dateGiven)
        ? _formatDate(vaccination!.dateGiven)
        : AppStrings.valueNotAvailable;
    final displayNextDue = _isValidDate(vaccination?.nextDueDate)
      ? _formatDate(vaccination!.nextDueDate)
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

    final displayEventTitle = event?.title.trim().isNotEmpty == true
      ? event!.title.trim()
      : AppStrings.valueNotAvailable;
    final displayEventType = _formatEventType(event?.eventType ?? 'general');
    final displayEventDate = _isValidDate(event?.date)
      ? _formatDate(event!.date)
      : AppStrings.valueNotAvailable;
    final displayEventFollowUp = _isValidDate(event?.followUpDate)
      ? _formatDate(event!.followUpDate!)
      : AppStrings.hintNotProvided;
    final displayEventProvider = event?.provider.trim().isNotEmpty == true
      ? event!.provider.trim()
      : AppStrings.valueNotAvailable;
    final displayEventClinic = event?.clinic.trim().isNotEmpty == true
      ? event!.clinic.trim()
      : AppStrings.valueNotAvailable;
    final displayEventPrice = event?.price == null
      ? AppStrings.hintNotProvided
      : '\$${event!.price!.toStringAsFixed(2)}';
    final displayEventNotes = event?.description.trim().isNotEmpty == true
      ? event!.description.trim()
      : AppStrings.eventNoNotes;

    final mainTitle = isVaccine ? displayVaccineName : displayEventTitle;
    final statusText = isVaccine ? displayVaccineStatus : displayEventType;
    final statusBackground =
      isVaccine ? AppColors.positiveBackground : AppColors.primaryVariant;
    final statusTextColor = isVaccine ? AppColors.success : AppColors.primary;
    final statusIcon = isVaccine ? Icons.check : Icons.label_rounded;

    final timelineTitle = isVaccine ? AppStrings.vaccineTimelineTitle : 'Schedule';
    final firstTimelineLabel =
      isVaccine ? AppStrings.vaccineDateGivenLabel : AppStrings.labelDate;
    final firstTimelineValue = isVaccine ? displayDateGiven : displayEventDate;
    final secondTimelineLabel =
      isVaccine ? AppStrings.vaccineNextDueLabel : 'Follow-up Date';
    final secondTimelineValue = isVaccine ? displayNextDue : displayEventFollowUp;

    final providerFirstLabel = isVaccine ? AppStrings.veterinarianLabel : 'Provider';
    final providerFirstValue = isVaccine ? displayVet : displayEventProvider;
    final providerSecondValue = isVaccine ? displayClinic : displayEventClinic;

    final lastCardTitle = isVaccine
      ? AppStrings.vaccineAttachedDocumentTitle
      : AppStrings.eventNotesTitle;
    final lastCardValue = isVaccine ? AppStrings.vaccineNoDocuments : displayEventNotes;

    final hasMutableData =
      (isVaccine && vaccination != null && pet != null) ||
      (isEvent && event != null);

    void showMissingDataMessage() {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.featureUnavailable)),
      );
    }

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
                const SizedBox(width: 8),
                Text(appbarTitle),
              ]
            ),
            const SizedBox(height: 2),
            if (displaySubtitle.isNotEmpty)
              Text(
                displaySubtitle,
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
                    Text(
                      mainTitle,
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
                            statusText,
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
                    if (isEvent) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.attach_money_outlined,
                        label: AppStrings.labelEventPrice,
                        value: displayEventPrice,
                      ),
                    ],
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
                  lastCardValue,
                  style: const TextStyle(
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
                    onPressed: hasMutableData
                        ? () => _confirmAndDelete(context)
                        : showMissingDataMessage,
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
                    onPressed: hasMutableData
                        ? () => navigateToEditPage(context)
                        : showMissingDataMessage,
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

bool _isValidDate(DateTime? date) {
  if (date == null) {
    return false;
  }

  return date.year > 1900;
}

String _formatEventType(String eventType) {
  final normalized = eventType.trim();
  if (normalized.isEmpty) {
    return 'General';
  }

  final words = normalized
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.trim().isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .toList(growable: false);

  if (words.isEmpty) {
    return 'General';
  }

  return words.join(' ');
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
