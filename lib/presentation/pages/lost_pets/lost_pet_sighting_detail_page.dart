import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/lost_pet_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/app_image_cache_manager.dart';
import '../../../core/services/lost_pet_service.dart';
import '../../../shared/widgets/lost_pet_map_preview.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';

class LostPetSightingDetailArgs {
  const LostPetSightingDetailArgs({required this.notification});

  final NotificationModel notification;
}

class LostPetSightingDetailPage extends StatefulWidget {
  const LostPetSightingDetailPage({super.key, required this.notification});

  final NotificationModel notification;

  @override
  State<LostPetSightingDetailPage> createState() =>
      _LostPetSightingDetailPageState();
}

class _LostPetSightingDetailPageState extends State<LostPetSightingDetailPage> {
  final LostPetService _lostPetService = LostPetService();

  LostPetReportModel? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _lostPetService.getLostPetDetail(
        widget.notification.actionReportId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _report = report);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = AppStrings.lostPetsLoadError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _callScanner() async {
    final phone = widget.notification.actionPhone.trim();
    if (phone.isEmpty) {
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openScannerWhatsApp() async {
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

  void _handleBottomNavTap(int index) {
    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final canCall = widget.notification.hasCallAction;
    final canWhatsApp = widget.notification.hasWhatsAppAction;

    return Scaffold(
      appBar: AppBar(title: const Text('Lost pet update'), centerTitle: true),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCall || canWhatsApp)
            _ScannerActionsBar(
              canCall: canCall,
              canWhatsApp: canWhatsApp,
              onCall: _callScanner,
              onWhatsApp: _openScannerWhatsApp,
            ),
          PetcareBottomNavBar(currentIndex: 2, onTap: _handleBottomNavTap),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasNotificationSnapshot =
        widget.notification.actionPetName.trim().isNotEmpty ||
        widget.notification.actionPetPhotoUrl.trim().isNotEmpty ||
        widget.notification.actionLocation.trim().isNotEmpty;
    if ((_errorMessage != null || _report == null) &&
        !hasNotificationSnapshot) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_rounded,
                size: 54,
                color: AppColors.grey300,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                _errorMessage ?? AppStrings.lostPetsLoadError,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              OutlinedButton(
                onPressed: _loadReport,
                child: const Text(AppStrings.lostPetsRetry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceXL,
      ),
      children: [
        _SightingHero(report: _report, notification: widget.notification),
        const SizedBox(height: AppDimensions.spaceM),
        _UpdatedLocationCard(
          notification: widget.notification,
          report: _report,
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _SightingTimeCard(notification: widget.notification),
        const SizedBox(height: AppDimensions.spaceM),
        _ScannerContactCard(notification: widget.notification),
      ],
    );
  }
}

class _SightingHero extends StatelessWidget {
  const _SightingHero({required this.report, required this.notification});

  final LostPetReportModel? report;
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final photoUrl = report?.photoUrl?.trim().isNotEmpty == true
        ? report!.photoUrl!.trim()
        : notification.actionPetPhotoUrl.trim();
    final petName = report?.petName.trim().isNotEmpty == true
        ? report!.petName.trim()
        : notification.actionPetName.trim().isNotEmpty
        ? notification.actionPetName.trim()
        : 'Lost pet';
    final subtitle = [
      report?.breed ?? '',
      report?.species ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' - ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: photoUrl,
                cacheManager: AppImageCacheManager.instance,
                fit: BoxFit.cover,
              )
            else
              Container(color: AppColors.primaryVariant),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppDimensions.spaceM,
              right: AppDimensions.spaceM,
              bottom: AppDimensions.spaceM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatedLocationCard extends StatelessWidget {
  const _UpdatedLocationCard({
    required this.notification,
    required this.report,
  });

  final NotificationModel notification;
  final LostPetReportModel? report;

  @override
  Widget build(BuildContext context) {
    final location = notification.actionLocation.trim().isNotEmpty
        ? notification.actionLocation.trim()
        : report?.lastSeen.name ?? '';
    final latitude = notification.actionLatitude ?? report?.lastSeen.latitude;
    final longitude =
        notification.actionLongitude ?? report?.lastSeen.longitude;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  'Location updated',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            location.isEmpty ? AppStrings.valueNotAvailable : location,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            LostPetMapPreview(
              latitude: latitude,
              longitude: longitude,
              height: 172,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScannerContactCard extends StatelessWidget {
  const _ScannerContactCard({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final phone = notification.actionPhone.trim();
    final reporterName = notification.actionReporterName.trim();
    return _SurfaceCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryVariant,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reporterName.isEmpty ? 'NFC scanner' : reporterName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  phone.isEmpty ? 'No contact shared' : phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SightingTimeCard extends StatelessWidget {
  const _SightingTimeCard({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final value = notification.dateSent;
    return _SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan time',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null ? AppStrings.valueNotAvailable : _format(value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey300,
        ),
      ),
      child: child,
    );
  }
}

class _ScannerActionsBar extends StatelessWidget {
  const _ScannerActionsBar({
    required this.canCall,
    required this.canWhatsApp,
    required this.onCall,
    required this.onWhatsApp,
  });

  final bool canCall;
  final bool canWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBackground,
        border: Border(top: BorderSide(color: AppColors.bottomNavTopBorder)),
      ),
      child: Row(
        children: [
          if (canCall)
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text(AppStrings.lostPetCall),
                ),
              ),
            ),
          if (canCall && canWhatsApp)
            const SizedBox(width: AppDimensions.spaceM),
          if (canWhatsApp)
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onWhatsApp,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: AppColors.onPrimary,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(AppStrings.lostPetWhatsApp),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
