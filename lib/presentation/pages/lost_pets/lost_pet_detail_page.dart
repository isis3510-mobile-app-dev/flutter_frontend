import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/lost_pet_model.dart';
import '../../../core/services/app_image_cache_manager.dart';
import '../../../core/services/lost_pet_service.dart';
import '../../../shared/widgets/lost_pet_map_preview.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';

class LostPetDetailPage extends StatefulWidget {
  const LostPetDetailPage({super.key, required this.initialReport});

  final LostPetReportModel initialReport;

  @override
  State<LostPetDetailPage> createState() => _LostPetDetailPageState();
}

class _LostPetDetailPageState extends State<LostPetDetailPage> {
  final LostPetService _lostPetService = LostPetService();

  late LostPetReportModel _report;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _report = widget.initialReport;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    try {
      final report = await _lostPetService.getLostPetDetail(_report.id);
      if (!mounted) {
        return;
      }
      setState(() => _report = report);
    } catch (_) {
      // The list card payload is enough for an offline fallback.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _callContact() async {
    final phone = _report.primaryContact?.phone.trim() ?? '';
    if (phone.isEmpty) {
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWhatsApp() async {
    final phone = _report.primaryContact?.whatsapp.trim() ?? '';
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
    final contact = _report.primaryContact;
    final canCall =
        contact?.allowCall == true && contact!.phone.trim().isNotEmpty;
    final canWhatsApp =
        contact?.allowWhatsApp == true && contact!.whatsapp.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.lostPetDetailTitle),
        centerTitle: true,
        actions: _isLoading
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: AppDimensions.spaceM),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pageHorizontalPadding,
          AppDimensions.spaceM,
          AppDimensions.pageHorizontalPadding,
          AppDimensions.spaceL,
        ),
        children: [
          _PhotoHeader(report: _report),
          const SizedBox(height: AppDimensions.spaceM),
          _LastSeenCard(report: _report),
          const SizedBox(height: AppDimensions.spaceM),
          if (_report.knownAllergies.trim().isNotEmpty) ...[
            _MedicalInfoCard(report: _report),
            const SizedBox(height: AppDimensions.spaceM),
          ],
          _SpecsGrid(report: _report),
          if (contact != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            _OwnerContactCard(contact: contact),
          ],
          if (_report.contacts.length > 1) ...[
            const SizedBox(height: AppDimensions.spaceM),
            _OwnerContactCard(
              contact: _report.contacts[1],
              title: AppStrings.lostPetEmergencyContacts,
            ),
          ],
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCall || canWhatsApp)
            _ContactActionsBar(
              canCall: canCall,
              canWhatsApp: canWhatsApp,
              onCall: _callContact,
              onWhatsApp: _openWhatsApp,
            ),
          PetcareBottomNavBar(currentIndex: 2, onTap: _handleBottomNavTap),
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PetPhoto(photoUrl: report.photoUrl, isDark: isDark),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.64),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppDimensions.spaceM,
              top: AppDimensions.spaceM,
              child: _LostBadge(report: report, isDark: isDark),
            ),
            Positioned(
              left: AppDimensions.spaceM,
              right: AppDimensions.spaceM,
              bottom: AppDimensions.spaceM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    _headline(report),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Wrap(
                    spacing: AppDimensions.spaceS,
                    runSpacing: AppDimensions.spaceXS,
                    children: [
                      if (report.gender.trim().isNotEmpty)
                        _HeroChip(label: report.gender.trim()),
                      if (report.ageLabel.trim().isNotEmpty)
                        _HeroChip(label: report.ageLabel.trim()),
                      if (report.weight != null)
                        _HeroChip(
                          label: '${report.weight!.toStringAsFixed(1)} kg',
                        ),
                      if (report.color.trim().isNotEmpty)
                        _HeroChip(label: report.color.trim()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headline(LostPetReportModel report) {
    final parts = [
      report.breed.trim().isEmpty ? report.species : report.breed,
      report.species,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(' · ');
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.photoUrl, required this.isDark});

  final String? photoUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return _PetPhotoPlaceholder(isDark: isDark);
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppImageCacheManager.instance,
      fit: BoxFit.cover,
      placeholder: (_, _) => _PetPhotoPlaceholder(isDark: isDark),
      errorWidget: (_, _, _) => _PetPhotoPlaceholder(isDark: isDark),
    );
  }
}

class _PetPhotoPlaceholder extends StatelessWidget {
  const _PetPhotoPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? AppColors.petCardQuickActionBgDark
          : AppColors.petCardQuickActionBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.pets_rounded,
        size: AppDimensions.iconXL,
        color: isDark
            ? AppColors.quickActionIconTintDark
            : AppColors.quickActionIconTint,
      ),
    );
  }
}

class _LostBadge extends StatelessWidget {
  const _LostBadge({required this.report, required this.isDark});

  final LostPetReportModel report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.negativeTextDark
        : AppColors.negativeText;
    final ageText = _timeAgo(report.createdAt ?? report.lastSeen.seenAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.negativeBackgroundDark
            : AppColors.petStatusLostBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.petDetailStatusLost.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (ageText.isNotEmpty) ...[
            const SizedBox(width: 7),
            Icon(Icons.schedule_rounded, size: 13, color: textColor),
            const SizedBox(width: 3),
            Text(
              ageText,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _LastSeenCard extends StatelessWidget {
  const _LastSeenCard({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.smartAlertInfoBgDark
        : AppColors.infoBackground;
    final foregroundColor = isDark
        ? AppColors.smartAlertInfoTextDark
        : AppColors.infoText;
    final iconBackgroundColor = isDark
        ? AppColors.petCardQuickActionBgDark
        : const Color(0xFF8FCAFF);
    final locationName = report.lastSeen.name.trim().isEmpty
        ? 'Bogotá'
        : report.lastSeen.name.trim();
    final seenAt = _formatDate(report.lastSeen.seenAt ?? report.createdAt);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on_outlined, color: foregroundColor),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.lostPetLastSeen,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (seenAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        seenAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (report.lastSeen.hasCoordinates) ...[
            const SizedBox(height: AppDimensions.spaceM),
            LostPetMapPreview(
              latitude: report.lastSeen.latitude,
              longitude: report.lastSeen.longitude,
              height: 148,
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicalInfoCard extends StatelessWidget {
  const _MedicalInfoCard({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark
        ? AppColors.overdueCardContentDark
        : AppColors.overdueCardContent;
    final allergies = report.knownAllergies.trim();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.overdueCardBackgroundDark
            : AppColors.overdueCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.overdueCardBorderDark
              : AppColors.overdueCardContent,
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: contentColor, size: 20),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                AppStrings.lostPetMedicalInfo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _MedicalLabel(text: 'Allergies:', color: contentColor),
          const SizedBox(height: AppDimensions.spaceXS),
          _MedicalPill(text: allergies),
        ],
      ),
    );
  }
}

class _MedicalLabel extends StatelessWidget {
  const _MedicalLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MedicalPill extends StatelessWidget {
  const _MedicalPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.overdueCardBorderDark
            : const Color(0xFFFFC878),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.overdueCardContentDark
              : AppColors.overdueCardContent,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    final specs = [
      _SpecItem('Species', report.species),
      _SpecItem('Breed', report.breed),
      _SpecItem('Color', report.color),
      if (report.weight != null)
        _SpecItem('Weight', '${report.weight!.toStringAsFixed(1)} kg'),
      if (report.microchipId.trim().isNotEmpty)
        _SpecItem('Microchip ID', report.microchipId.trim()),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppDimensions.spaceS) / 2;
        return Wrap(
          spacing: AppDimensions.spaceS,
          runSpacing: AppDimensions.spaceS,
          children: specs
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _SpecTile(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SpecItem {
  const _SpecItem(this.label, this.value);

  final String label;
  final String value;
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.item});

  final _SpecItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      constraints: const BoxConstraints(minHeight: 78),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardQuickActionBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey900,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerContactCard extends StatelessWidget {
  const _OwnerContactCard({
    required this.contact,
    this.title = AppStrings.lostPetOwnerContact,
  });

  final LostPetContactModel contact;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryVariant,
                foregroundColor: AppColors.primary,
                child: Text(
                  _initials(contact.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      contact.relationship,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (contact.allowCall && contact.phone.trim().isNotEmpty)
            _ContactInfoPill(icon: Icons.call_outlined, text: contact.phone),
          if (contact.allowWhatsApp && contact.whatsapp.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceS),
            const _ContactInfoPill(
              icon: Icons.chat_bubble_outline_rounded,
              text: AppStrings.lostPetWhatsApp,
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ContactInfoPill extends StatelessWidget {
  const _ContactInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardQuickActionBgDark
            : AppColors.petCardQuickActionBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.grey900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionsBar extends StatelessWidget {
  const _ContactActionsBar({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bottomNavBackgroundDark
            : AppColors.bottomNavBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.bottomNavTopBorderDark
                : AppColors.bottomNavTopBorder,
          ),
        ),
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

String _formatDate(DateTime? value) {
  if (value == null || value.year <= 1) {
    return '';
  }

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
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _timeAgo(DateTime? value) {
  if (value == null || value.year <= 1) {
    return '';
  }

  final difference = DateTime.now().difference(value);
  if (difference.inDays >= 1) {
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }
  if (difference.inHours >= 1) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  return 'Today';
}
