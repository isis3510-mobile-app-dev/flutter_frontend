import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/add_event/add_event_args.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class DetailPage extends StatelessWidget {
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

  bool get _isEvent => type == 'event';
  bool get _isVaccine => type == 'vaccine';

  Future<void> _confirmAndDelete(BuildContext context) async {
    if (_isVaccine) {
      await _confirmAndDeleteVaccine(context);
      return;
    }

    if (_isEvent) {
      await _confirmAndDeleteEvent(context);
    }
  }

  Future<void> _confirmAndDeleteVaccine(BuildContext context) async {
    if (vaccination == null || pet == null) {
      _showUnavailableMessage(context);
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
        petId: pet!.id,
        vaccinationId: vaccination!.id,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccine deleted successfully.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    }
  }

  Future<void> _confirmAndDeleteEvent(BuildContext context) async {
    if (event == null || event!.id.trim().isEmpty) {
      _showUnavailableMessage(context);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('Are you sure you want to delete this event?'),
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
      await EventService().deleteEvent(event!.id);

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    }
  }

  Future<void> _navigateToEditPage(BuildContext context) async {
    if (_isVaccine) {
      final result = await Navigator.of(context).pushNamed(
        Routes.addVaccine,
        arguments: AddVaccineArgs(
          vaccinationId: vaccination?.id,
          vaccineId: vaccination?.vaccineId,
          vaccineName: vaccineName,
          dateGiven: vaccination?.dateGiven,
          petId: pet?.id,
          petName: pet?.name,
          administeredBy: vaccination?.administeredBy,
        ),
      );

      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (_isEvent) {
      if (event == null || event!.id.trim().isEmpty) {
        _showUnavailableMessage(context);
        return;
      }

      final result = await Navigator.of(context).pushNamed(
        Routes.addEvent,
        arguments: AddEventArgs(
          eventId: event!.id,
          ownerId: event!.ownerId,
          petId: event!.petId,
          petName: pet?.name,
          eventName: event!.title,
          eventType: event!.eventType,
          dateTime: event!.date,
          provider: event!.provider,
          clinic: event!.clinic,
          description: event!.description,
          price: event!.price,
          followUpDate: event!.followUpDate,
          attachedDocuments: event!.attachedDocuments,
        ),
      );

      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showUnavailableMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appbarIcon = _isVaccine
        ? Icons.vaccines_outlined
        : _isEvent
            ? Icons.event_note_outlined
            : Icons.info_outline;

    final appbarTitle = _isVaccine
        ? AppStrings.vaccineDetailsTitle
        : _isEvent
            ? AppStrings.eventDetailsTitle
            : '';

    final displayPetName = pet?.name.trim().isNotEmpty == true
        ? pet!.name.trim()
        : _isEvent && (event?.petId.trim().isNotEmpty ?? false)
            ? event!.petId.trim()
            : AppStrings.valueNotAvailable;

    final displayPetSpecies = pet?.species.trim().isNotEmpty == true
        ? pet!.species.trim()
        : '';

    final displaySubtitle = displayPetSpecies.isNotEmpty
        ? '$displayPetName - $displayPetSpecies'
        : displayPetName;

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
              children: [
                Icon(appbarIcon),
                const SizedBox(width: 8),
                Text(appbarTitle),
              ],
            ),
            const SizedBox(height: 2),
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
            children: _isVaccine
                ? _buildVaccineCards(context)
                : _isEvent
                    ? _buildEventCards(context)
                    : const [],
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
                    onPressed: () => _navigateToEditPage(context),
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

  List<Widget> _buildVaccineCards(BuildContext context) {
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
        ? _formatDate(vaccination!.nextDueDate)
        : AppStrings.hintNotProvided;

    final displayVet = vaccination?.administeredBy.trim().isNotEmpty == true
        ? vaccination!.administeredBy.trim()
        : pet?.defaultVet.trim().isNotEmpty == true
            ? pet!.defaultVet.trim()
            : AppStrings.valueNotAvailable;

    final displayClinic = vaccination?.clinicName.trim().isNotEmpty == true
        ? vaccination!.clinicName.trim()
        : AppStrings.valueNotAvailable;

    return [
      _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    style: const TextStyle(
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
        title: AppStrings.vaccineAttachedDocumentTitle,
        child: Text(
          AppStrings.vaccineNoDocuments,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey700,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildEventCards(BuildContext context) {
    final displayEventName = event?.title.trim().isNotEmpty == true
        ? event!.title.trim()
        : _humanizeEventType(event?.eventType) ?? AppStrings.valueNotAvailable;

    final displayEventType = _humanizeEventType(event?.eventType) ?? AppStrings.valueNotAvailable;

    final displayDate = event?.date != null
        ? _formatDate(event!.date)
        : AppStrings.valueNotAvailable;

    final displayTime = event?.date != null
        ? _formatTime(event!.date)
        : AppStrings.hintNotProvided;

    final displayFollowUpDate = event?.followUpDate != null
        ? _formatDate(event!.followUpDate!)
        : AppStrings.hintNotProvided;

    final displayPrice = event?.price != null
        ? _formatCurrency(event!.price!)
        : AppStrings.hintNotProvided;

    final displayProvider = _firstNonEmpty(
      [event?.provider],
      fallback: AppStrings.valueNotAvailable,
    );

    final displayClinic = _firstNonEmpty(
      [event?.clinic],
      fallback: AppStrings.valueNotAvailable,
    );

    final displayDescription = _firstNonEmpty(
      [event?.description],
      fallback: AppStrings.eventNoNotes,
    );

    return [
      _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayEventName,
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
                color: AppColors.primaryVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    displayEventType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
        title: 'Event Schedule',
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: AppStrings.labelDate,
              value: displayDate,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: AppStrings.labelEventTime,
              value: displayTime,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.update_outlined,
              label: 'Follow-up Date',
              value: displayFollowUpDate,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.attach_money_outlined,
              label: 'Price',
              value: displayPrice,
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
              label: 'Provider',
              value: displayProvider,
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
        title: AppStrings.eventNotesTitle,
        child: Text(
          displayDescription,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey700,
          ),
        ),
      ),
    ];
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

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _formatDateForApi(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _humanizeEventType(String? eventType) {
  final value = (eventType ?? '').trim();
  if (value.isEmpty) {
    return null;
  }

  final spaced = value
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (spaced.isEmpty) {
    return null;
  }

  final words = spaced
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .toList(growable: false);

  if (words.isEmpty) {
    return null;
  }

  return words.join(' ');
}

String _firstNonEmpty(List<String?> values, {required String fallback}) {
  for (final value in values) {
    final normalized = (value ?? '').trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return fallback;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
