import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/local_asset_store_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_frontend/presentation/pages/add_event/add_event_args.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final EventService _eventService = EventService();
  final LocalAssetStoreService _localAssetStore = LocalAssetStoreService();

  PetVaccinationModel? _vaccination;
  PetModel? _pet;
  String? _vaccineName;
  EventModel? _event;

  @override
  void initState() {
    super.initState();
    _vaccination = widget.vaccination;
    _pet = widget.pet;
    _vaccineName = widget.vaccineName;
    _event = widget.event;
    if (widget.type == 'vaccine') {
      _refreshVaccination();
    }
    if (widget.type == 'event') {
      _refreshEvent();
    }
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
    if (widget.type == 'vaccine' && (_vaccination == null || _pet == null)) {
      return;
    }

    if (widget.type == 'event' && widget.event == null) {
      return;
    }

    final isEvent = widget.type == 'event';

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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
        await _eventService.deleteEvent(_event!.id);
      } else {
        await PetService().deleteVaccination(
          petId: _pet!.id,
          vaccinationId: _vaccination!.id,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
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
          attachedDocuments: _vaccination?.attachedDocuments,
        ),
      );
      if (result == true) {
        await _refreshVaccination();
      }
    } else if (widget.type == 'event') {
      final result = await Navigator.of(context).pushNamed(
        Routes.addEvent,
        arguments: AddEventArgs(
          eventId: _event?.id,
          petId: _pet?.id,
          petName: _pet?.name,
          title: _event?.title,
          description: _event?.description,
          date: _event?.date,
          eventType: _event?.eventType,
          price: _event?.price,
          provider: _event?.provider,
          clinic: _event?.clinic,
          followUpDate: _event?.followUpDate,
          attachedDocuments: _event?.attachedDocuments,
        ),
      );

      if (result == true) {
        await _refreshEvent();
      }
    }
  }

  Future<void> _refreshEvent() async {
    if (widget.type != 'event' || _event == null || _event!.id.trim().isEmpty) {
      return;
    }

    try {
      final updatedEvent = await _eventService.getEventById(_event!.id);

      if (!mounted) return;
      setState(() {
        _event = updatedEvent;
      });
    } catch (_) {
      // Keep existing data if refresh fails.
    }
  }

  Future<void> _openDocument(_DocumentItem document) async {
    final remoteUrl = document.url.trim();
    if (remoteUrl.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
      return;
    }

    try {
      final localPath = await _localAssetStore.ensureLocalCopyFromRemote(
        remoteUrl: remoteUrl,
        category: _documentCategory,
        fileName: document.name,
        stableId: document.documentId,
      );

      if (localPath != null && localPath.trim().isNotEmpty) {
        try {
          final result = await OpenFilex.open(localPath);
          if (result.type == ResultType.done || !mounted) {
            return;
          }
        } catch (_) {
          // If local opening fails, continue with remote fallback.
        }
      }

      final remoteUri = Uri.tryParse(remoteUrl);
      if (remoteUri == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorGeneric)),
        );
        return;
      }

      final opened = await launchUrl(
        remoteUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document opening is not available right now.'),
        ),
      );
    }
  }

  String get _documentCategory {
    return widget.type == 'event'
        ? 'documents/events'
        : 'documents/vaccines';
  }

  @override
  Widget build(BuildContext context) {
    final (appbarIcon, appbarTitle, lastCardTitle) = switch (widget.type) {
      'vaccine' => (
        Icons.vaccines_outlined,
        AppStrings.vaccineDetailsTitle,
        AppStrings.vaccineAttachedDocumentTitle,
      ),
      'event' => (
        Icons.event_note_outlined,
        AppStrings.eventDetailsTitle,
        AppStrings.eventDocumentsTitle,
      ),
      _ => (Icons.info_outline, '', ''),
    };

    final isVaccine = widget.type == 'vaccine';
    final isEvent = widget.type == 'event';

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
    final displayVaccineStatus = _vaccination?.status.trim().isNotEmpty == true
        ? _vaccination!.status.trim()
        : AppStrings.vaccineStatusCompleted;
    final displayDateGiven = _isValidDate(_vaccination?.dateGiven)
        ? _formatDate(_vaccination!.dateGiven)
        : AppStrings.valueNotAvailable;
    final displayNextDue = _isValidDate(_vaccination?.nextDueDate)
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

    final displayEventTitle = _event?.title.trim().isNotEmpty == true
        ? _event!.title.trim()
        : AppStrings.valueNotAvailable;
    final displayEventType = _formatEventType(_event?.eventType ?? 'general');
    final displayEventDate = _isValidDate(_event?.date)
        ? _formatDate(_event!.date)
        : AppStrings.valueNotAvailable;
    final displayEventFollowUp = _isValidDate(_event?.followUpDate)
        ? _formatDate(_event!.followUpDate!)
        : AppStrings.hintNotProvided;
    final displayEventProvider = _event?.provider.trim().isNotEmpty == true
        ? _event!.provider.trim()
        : AppStrings.valueNotAvailable;
    final displayEventClinic = _event?.clinic.trim().isNotEmpty == true
        ? _event!.clinic.trim()
        : AppStrings.valueNotAvailable;
    final displayEventPrice = _event?.price == null
        ? AppStrings.hintNotProvided
        : '\$${_event!.price!.toStringAsFixed(2)}';
    final displayEventNotes = _event?.description.trim().isNotEmpty == true
        ? _event!.description.trim()
        : AppStrings.eventNoNotes;
    final vaccineDocuments =
        _vaccination?.attachedDocuments ?? const <PetDocumentModel>[];
    final eventDocuments =
        _event?.attachedDocuments ?? const <EventDocumentModel>[];

    final mainTitle = isVaccine ? displayVaccineName : displayEventTitle;
    final statusText = isVaccine ? displayVaccineStatus : displayEventType;
    final timelineTitle = isVaccine
        ? AppStrings.vaccineTimelineTitle
        : 'Schedule';
    final firstTimelineLabel = isVaccine
        ? AppStrings.vaccineDateGivenLabel
        : AppStrings.labelDate;
    final firstTimelineValue = isVaccine ? displayDateGiven : displayEventDate;
    final secondTimelineLabel = isVaccine
        ? AppStrings.vaccineNextDueLabel
        : 'Follow-up Date';
    final secondTimelineValue = isVaccine
        ? displayNextDue
        : displayEventFollowUp;

    final providerFirstLabel = isVaccine
        ? AppStrings.veterinarianLabel
        : 'Provider';
    final providerFirstValue = isVaccine ? displayVet : displayEventProvider;
    final providerSecondValue = isVaccine ? displayClinic : displayEventClinic;

    final hasMutableData =
        (isVaccine && _vaccination != null && _pet != null) ||
        (isEvent && _event != null);

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
              ],
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
                backgroundColor: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            Icons.check,
                            size: 16,
                            color: isDark
                                ? AppColors.positiveTextDark
                                : AppColors.positiveText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
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
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: timelineTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: firstTimelineLabel,
                      value: firstTimelineValue,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: secondTimelineLabel,
                      value: secondTimelineValue,
                      isDark: isDark,
                    ),
                    if (isEvent) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.attach_money_outlined,
                        label: AppStrings.labelEventPrice,
                        value: displayEventPrice,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                backgroundColor: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: AppStrings.providerInfoTitle,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: providerFirstLabel,
                      value: providerFirstValue,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: AppStrings.clinicLabel,
                      value: providerSecondValue,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isEvent) ...[
                _InfoCard(
                  backgroundColor: isDark
                      ? AppColors.secondaryDark
                      : AppColors.secondary,
                  borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                  title: AppStrings.eventNotesTitle,
                  child: Text(
                    displayEventNotes,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.onSurfaceDark.withValues(alpha: 0.82)
                          : AppColors.grey700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _InfoCard(
                backgroundColor: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondary,
                borderColor: isDark ? AppColors.grey700 : AppColors.grey300,
                title: lastCardTitle,
                child: isVaccine
                    ? _DocumentsList(
                        documents: vaccineDocuments
                            .map(
                              (doc) => _DocumentItem(
                                documentId: doc.documentId,
                                name: doc.fileName,
                                url: doc.fileUri,
                              ),
                            )
                            .toList(growable: false),
                        emptyLabel: AppStrings.vaccineNoDocuments,
                        onOpenDocument: _openDocument,
                      )
                    : _DocumentsList(
                        documents: eventDocuments
                            .map(
                              (doc) => _DocumentItem(
                                documentId: doc.documentId,
                                name: doc.fileName,
                                url: doc.fileUri,
                              ),
                            )
                            .toList(growable: false),
                        emptyLabel: AppStrings.vaccineNoDocuments,
                        onOpenDocument: _openDocument,
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
        ),
      ),
    );
  }
}

class _DocumentItem {
  const _DocumentItem({
    required this.name,
    required this.url,
    this.documentId,
  });

  final String name;
  final String url;
  final String? documentId;
}

class _DocumentsList extends StatelessWidget {
  const _DocumentsList({
    required this.documents,
    required this.emptyLabel,
    required this.onOpenDocument,
  });

  final List<_DocumentItem> documents;
  final String emptyLabel;
  final Future<void> Function(_DocumentItem document) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Text(
        emptyLabel,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.onSurfaceDark.withValues(alpha: 0.72)
              : AppColors.grey700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(documents.length, (index) {
        final document = documents[index];
        final name = document.name.trim().isEmpty
            ? 'Document ${index + 1}'
            : document.name.trim();
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == documents.length - 1 ? 0 : 10,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: document.url.trim().isEmpty
                ? null
                : () => onOpenDocument(document),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey700,
                      ),
                    ),
                  ),
                  if (document.url.trim().isNotEmpty)
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
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
  const _InfoCard({
    this.title,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

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
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
    final iconColor = isDark ? AppColors.grey300 : AppColors.grey700;
    final labelColor = isDark ? AppColors.grey300 : AppColors.grey700;
    final valueColor = isDark ? AppColors.onSurfaceDark : AppColors.onSecondary;

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(color: labelColor),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
