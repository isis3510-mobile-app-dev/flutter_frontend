import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/lost_pet_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/models/smart_alert_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_image_cache_manager.dart';
import '../../../core/services/app_preferences_service.dart';
import '../../../core/services/lost_pet_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/connectivity_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/smart_feature_service.dart';
import '../lost_pets/lost_pet_sighting_detail_page.dart';
import '../../../shared/widgets/smart_alert_card.dart';

class SmartAlertsPage extends StatefulWidget {
  const SmartAlertsPage({super.key, this.initialPetId});

  final String? initialPetId;

  @override
  State<SmartAlertsPage> createState() => _SmartAlertsPageState();
}

class _SmartAlertsPageState extends State<SmartAlertsPage> {
  final PetService _petService = PetService();
  final SmartFeatureService _smartFeatureService = SmartFeatureService();
  final NotificationService _notificationService = NotificationService();
  final LostPetService _lostPetService = LostPetService();
  final AppPreferencesService _preferencesService = AppPreferencesService();

  List<PetModel> _pets = const [];
  List<SmartAlertItem> _alerts = const [];
  List<NotificationModel> _notifications = const [];
  Map<String, LostPetReportModel> _lostPetReportsByReportId = const {};
  final Set<String> _dismissedNotificationIds = <String>{};
  String? _selectedPetId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPetId = _normalizePetId(widget.initialPetId);
    _loadAlerts();
  }

  String? _normalizePetId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dismissedIds = await _preferencesService
          .getDismissedLostPetNotificationIds();
      _dismissedNotificationIds
        ..clear()
        ..addAll(dismissedIds);
      final pets = await _petService.getPets();
      final notifications = await _loadBackendNotificationsBestEffort();
      final reportMap = await _loadLostPetReportsForNotifications(
        notifications,
      );

      final alertGroups = await Future.wait(
        pets.map((pet) async {
          try {
            final response = await _smartFeatureService.getPetSmartSuggestions(
              pet.id,
            );
            final displayPetName = pet.name.trim().isNotEmpty
                ? pet.name.trim()
                : response.petName.trim().isNotEmpty
                ? response.petName.trim()
                : AppStrings.valueNotAvailable;

            return response.suggestions
                .map(
                  (suggestion) => SmartAlertItem(
                    petId: pet.id,
                    petName: displayPetName,
                    suggestion: suggestion,
                  ),
                )
                .toList(growable: false);
          } catch (_) {
            return const <SmartAlertItem>[];
          }
        }),
      );

      if (!mounted) {
        return;
      }

      final alerts = alertGroups
          .expand((group) => group)
          .toList(growable: false);
      final availablePetIds = pets.map((pet) => pet.id).toSet();
      final normalizedSelection = _selectedPetId;

      setState(() {
        _pets = pets;
        _notifications = notifications
            .where(
              (notification) =>
                  !_dismissedNotificationIds.contains(notification.id),
            )
            .toList(growable: false);
        _lostPetReportsByReportId = reportMap;
        _alerts = alerts;
        _selectedPetId =
            normalizedSelection != null &&
                availablePetIds.contains(normalizedSelection)
            ? normalizedSelection
            : null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppStrings.errorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<NotificationModel>> _loadBackendNotificationsBestEffort() async {
    try {
      final notifications = await _notificationService.getMyNotifications();
      final sightings = notifications
          .where((notification) => notification.type == 'lost_pet_sighting')
          .toList(growable: false);
      return _latestSightingNotifications(sightings);
    } catch (_) {
      return const <NotificationModel>[];
    }
  }

  Future<Map<String, LostPetReportModel>> _loadLostPetReportsForNotifications(
    List<NotificationModel> notifications,
  ) async {
    final entries = <MapEntry<String, LostPetReportModel>>[];
    for (final notification in notifications) {
      final reportId = notification.actionReportId.trim();
      if (reportId.isEmpty) {
        continue;
      }
      try {
        final report = await _lostPetService.getLostPetDetail(reportId);
        entries.add(MapEntry(reportId, report));
      } catch (_) {
        // The notification can still render without the report payload.
      }
    }
    return Map<String, LostPetReportModel>.fromEntries(entries);
  }

  List<NotificationModel> _latestSightingNotifications(
    List<NotificationModel> notifications,
  ) {
    final sorted = [...notifications]
      ..sort((a, b) {
        final aDate = a.dateSent ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.dateSent ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.take(1).toList(growable: false);
  }

  List<SmartAlertItem> get _visibleAlerts {
    final selectedPetId = _selectedPetId;
    if (selectedPetId == null) {
      return _alerts;
    }
    return _alerts
        .where((item) => item.petId == selectedPetId)
        .toList(growable: false);
  }

  int _countForPet(String petId) {
    return _alerts.where((item) => item.petId == petId).length;
  }

  Future<void> _dismissNotification(NotificationModel notification) async {
    setState(() {
      _dismissedNotificationIds.add(notification.id);
      _notifications = _notifications
          .where((item) => item.id != notification.id)
          .toList(growable: false);
    });
    await _preferencesService.setDismissedLostPetNotificationIds(
      _dismissedNotificationIds,
    );
  }

  void _openLostPetSighting(NotificationModel notification) {
    if (!notification.hasLostPetReport) {
      return;
    }
    Navigator.of(context).pushNamed(
      Routes.lostPetSightingDetail,
      arguments: LostPetSightingDetailArgs(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.smartAlertsPageTitle),
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const SizedBox(height: AppDimensions.spaceS),
          _buildInternetNotice(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 56,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grey700),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    OutlinedButton(
                      onPressed: _loadAlerts,
                      child: const Text(AppStrings.petsRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final visibleAlerts = _visibleAlerts;
    final hasContent = _notifications.isNotEmpty || visibleAlerts.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceS),
        _buildInternetNotice(),
        const SizedBox(height: AppDimensions.spaceM),
        _buildFilterBar(),
        const SizedBox(height: AppDimensions.spaceM),
        Expanded(
          child: !hasContent
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      top: AppDimensions.spaceS,
                      bottom: AppDimensions.spaceXXL,
                    ),
                    itemCount: _notifications.length + visibleAlerts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spaceS),
                    itemBuilder: (context, index) {
                      if (index < _notifications.length) {
                        return _LostPetNotificationCard(
                          notification: _notifications[index],
                          report:
                              _lostPetReportsByReportId[_notifications[index]
                                  .actionReportId],
                          onDismiss: () =>
                              _dismissNotification(_notifications[index]),
                          onOpen: () =>
                              _openLostPetSighting(_notifications[index]),
                        );
                      }

                      final alert =
                          visibleAlerts[index - _notifications.length];
                      return SmartAlertCard(
                        suggestion: alert.suggestion,
                        petName: alert.petName,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.pageHorizontalPadding,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInternetNotice() {
    return FutureBuilder<bool>(
      future: ConnectivitySyncService().hasInternetAccess(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final hasInternet = snapshot.data == true;
        if (hasInternet) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceM,
          ),
          decoration: BoxDecoration(
            color: AppColors.smartAlertInfoBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppColors.smartAlertInfoText,
                size: 20,
              ),
              SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  AppStrings.smartAlertsInternetNotice,
                  style: TextStyle(
                    color: AppColors.smartAlertInfoText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final petOptions = _pets
        .where((pet) {
          final count = _countForPet(pet.id);
          return count > 0 || _selectedPetId == pet.id;
        })
        .toList(growable: false);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        child: Row(
          children: [
            _AlertFilterChip(
              label: AppStrings.smartAlertsFilterAll,
              isSelected: _selectedPetId == null,
              onTap: () => setState(() => _selectedPetId = null),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            for (final pet in petOptions) ...[
              _AlertFilterChip(
                label:
                    '${pet.name.trim().isEmpty ? AppStrings.valueNotAvailable : pet.name.trim()} (${_countForPet(pet.id)})',
                isSelected: _selectedPetId == pet.id,
                onTap: () => setState(() => _selectedPetId = pet.id),
              ),
              const SizedBox(width: AppDimensions.spaceS),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        child: Text(
          AppStrings.smartAlertsEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.grey700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LostPetNotificationCard extends StatefulWidget {
  const _LostPetNotificationCard({
    required this.notification,
    required this.report,
    required this.onDismiss,
    required this.onOpen,
  });

  final NotificationModel notification;
  final LostPetReportModel? report;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  State<_LostPetNotificationCard> createState() =>
      _LostPetNotificationCardState();
}

class _LostPetNotificationCardState extends State<_LostPetNotificationCard> {
  bool _isExpanded = false;

  Future<void> _call() async {
    final phone = widget.notification.actionPhone.trim();
    if (phone.isEmpty) {
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.notification.actionWhatsapp.trim();
    if (phone.isEmpty) {
      return;
    }
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(
      Uri.parse('https://wa.me/$normalizedPhone'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final report = widget.report;
    if (notification.type != 'lost_pet_sighting') {
      return const SizedBox.shrink();
    }

    final hasActions =
        notification.hasCallAction || notification.hasWhatsAppAction;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.smartAlertInfoBgDark
        : AppColors.smartAlertInfoBg;
    final textColor = isDark
        ? AppColors.smartAlertInfoTextDark
        : AppColors.smartAlertInfoText;

    return Dismissible(
      key: ValueKey('lost-pet-notification-${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.negativeText.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.negativeText,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.notification.hasLostPetReport
                  ? widget.onOpen
                  : () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationPetPhoto(
                    notification: notification,
                    report: report,
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _finderLabel(notification, report),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        _NotificationSummary(
                          notification: notification,
                          report: report,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  _NotificationIconButton(
                    icon: _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: textColor,
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                  _NotificationIconButton(
                    icon: Icons.close_rounded,
                    color: textColor,
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
            if (_isExpanded && notification.dateSent != null) ...[
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                _formatDate(notification.dateSent!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_isExpanded &&
                (notification.hasLostPetReport || hasActions)) ...[
              const SizedBox(height: AppDimensions.spaceS),
              Wrap(
                spacing: AppDimensions.spaceS,
                runSpacing: AppDimensions.spaceS,
                children: [
                  if (notification.hasLostPetReport)
                    _NotificationActionChip(
                      icon: Icons.open_in_new_rounded,
                      label: 'View update',
                      color: textColor,
                      onPressed: widget.onOpen,
                    ),
                  if (notification.hasCallAction)
                    _NotificationActionChip(
                      icon: Icons.call_rounded,
                      label: AppStrings.lostPetCall,
                      color: textColor,
                      onPressed: _call,
                    ),
                  if (notification.hasWhatsAppAction)
                    _NotificationActionChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: AppStrings.lostPetWhatsApp,
                      color: textColor,
                      onPressed: _openWhatsApp,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }

  String _finderLabel(
    NotificationModel notification,
    LostPetReportModel? report,
  ) {
    final name = _finderName(notification);
    final petName = report?.petName.trim().isNotEmpty == true
        ? report!.petName.trim()
        : notification.actionPetName.trim();
    final petLabel = petName.isEmpty ? 'your pet' : petName;
    return name.isEmpty ? 'Someone found $petLabel' : '$name found $petLabel';
  }

  String _finderName(NotificationModel notification) {
    final structuredName = notification.actionReporterName.trim();
    if (structuredName.isNotEmpty) {
      return structuredName;
    }

    final text = notification.text.trim();
    final match = RegExp(r'^(.*?) scanned ').firstMatch(text);
    final name = match?.group(1)?.trim() ?? '';
    return name == 'Someone' ? '' : name;
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 22, color: color.withValues(alpha: 0.9)),
      ),
    );
  }
}

class _NotificationActionChip extends StatelessWidget {
  const _NotificationActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.56)),
        minimumSize: const Size(0, 44),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceS,
        ),
      ),
    );
  }
}

class _NotificationPetPhoto extends StatelessWidget {
  const _NotificationPetPhoto({
    required this.notification,
    required this.report,
  });

  final NotificationModel notification;
  final LostPetReportModel? report;

  @override
  Widget build(BuildContext context) {
    final reportPhotoUrl = report?.photoUrl?.trim() ?? '';
    final photoUrl = reportPhotoUrl.isNotEmpty
        ? reportPhotoUrl
        : notification.actionPetPhotoUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: SizedBox(
        width: 44,
        height: 44,
        child: photoUrl.isEmpty
            ? Container(
                color: AppColors.smartAlertInfoText.withValues(alpha: 0.16),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.smartAlertInfoText,
                ),
              )
            : CachedNetworkImage(
                imageUrl: photoUrl,
                cacheManager: AppImageCacheManager.instance,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.notification,
    required this.report,
    required this.textColor,
  });

  final NotificationModel notification;
  final LostPetReportModel? report;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final location = notification.actionLocation.trim().isNotEmpty
        ? notification.actionLocation.trim()
        : AppStrings.valueNotAvailable;
    final petName = report?.petName.trim().isNotEmpty == true
        ? report!.petName.trim()
        : notification.actionPetName.trim().isNotEmpty
        ? notification.actionPetName.trim()
        : 'Lost pet';
    final time = notification.dateSent == null
        ? ''
        : _relativeTime(notification.dateSent!);
    final rows = [
      _SummaryRowData(
        icon: Icons.person_outline_rounded,
        label: 'Finder',
        value: _finderName(notification).isEmpty
            ? 'Contact not shared'
            : _finderName(notification),
      ),
      _SummaryRowData(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: location,
      ),
      _SummaryRowData(icon: Icons.pets_rounded, label: 'Pet', value: petName),
      if (time.isNotEmpty)
        _SummaryRowData(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: time,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          _NotificationSummaryRow(row: row, color: textColor),
          const SizedBox(height: 3),
        ],
      ],
    );
  }

  String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  String _finderName(NotificationModel notification) {
    final structuredName = notification.actionReporterName.trim();
    if (structuredName.isNotEmpty) {
      return structuredName;
    }

    final text = notification.text.trim();
    final match = RegExp(r'^(.*?) scanned ').firstMatch(text);
    final name = match?.group(1)?.trim() ?? '';
    return name == 'Someone' ? '' : name;
  }
}

class _SummaryRowData {
  const _SummaryRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _NotificationSummaryRow extends StatelessWidget {
  const _NotificationSummaryRow({required this.row, required this.color});

  final _SummaryRowData row;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 15, color: color.withValues(alpha: 0.74)),
        const SizedBox(width: AppDimensions.spaceXS),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${row.label}: ',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: row.value,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _AlertFilterChip extends StatelessWidget {
  const _AlertFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foregroundColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.grey500 : AppColors.grey700);
    final backgroundColor = isSelected
        ? AppColors.bottomNavActive
        : (isDark ? AppColors.secondaryDark : AppColors.secondary);
    final borderColor = isSelected
        ? AppColors.bottomNavActive
        : (isDark ? AppColors.grey700 : AppColors.grey300);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
