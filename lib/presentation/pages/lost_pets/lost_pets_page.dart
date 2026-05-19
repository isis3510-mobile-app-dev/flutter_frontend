import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/lost_pet_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_image_cache_manager.dart';
import '../../../core/services/lost_pet_service.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';

class LostPetsPage extends StatefulWidget {
  const LostPetsPage({super.key});

  @override
  State<LostPetsPage> createState() => _LostPetsPageState();
}

class _LostPetsPageState extends State<LostPetsPage> {
  final LostPetService _lostPetService = LostPetService();
  final TextEditingController _searchController = TextEditingController();

  List<LostPetReportModel> _reports = const [];
  _LostPetFilter _activeFilter = _LostPetFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLostPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLostPets({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _lostPetService.getLostPets(
        forceRefresh: forceRefresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reports.where((report) => report.isActive).toList();
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
        _errorMessage = AppStrings.lostPetsLoadError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBottomNavTap(int index) {
    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This section is not available yet.')),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  void _openDetail(LostPetReportModel report) {
    Navigator.of(context).pushNamed(Routes.lostPetDetail, arguments: report);
  }

  Future<void> _callOwner(LostPetReportModel report) async {
    final phone = report.primaryContact?.phone.trim() ?? '';
    if (phone.isEmpty) {
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  List<LostPetReportModel> get _filteredReports {
    final normalizedQuery = _normalizeSearch(_searchQuery);
    return _reports
        .where((report) {
          final matchesFilter = switch (_activeFilter) {
            _LostPetFilter.all => true,
            _LostPetFilter.dogs => report.species.trim().toLowerCase() == 'dog',
            _LostPetFilter.cats => report.species.trim().toLowerCase() == 'cat',
          };
          if (!matchesFilter) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return _searchableText(report).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _searchableText(LostPetReportModel report) {
    final contact = report.primaryContact;
    return _normalizeSearch(
      [
        report.petName,
        report.species,
        report.breed,
        report.color,
        report.gender,
        report.lastSeen.name,
        report.lostNote,
        contact?.name ?? '',
        contact?.relationship ?? '',
      ].join(' '),
    );
  }

  String _normalizeSearch(String value) {
    return value.trim().toLowerCase();
  }

  int _countFor(_LostPetFilter filter) {
    return _reports.where((report) {
      return switch (filter) {
        _LostPetFilter.all => true,
        _LostPetFilter.dogs => report.species.trim().toLowerCase() == 'dog',
        _LostPetFilter.cats => report.species.trim().toLowerCase() == 'cat',
      };
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(count: _reports.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadLostPets(forceRefresh: true),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: 2,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadLostPets);
    }

    final filteredReports = _filteredReports;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        0,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceXXL,
      ),
      itemCount: filteredReports.isEmpty ? 4 : filteredReports.length + 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceM),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _HelpBanner();
        }

        if (index == 1) {
          return _LostPetSearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: _searchQuery.isEmpty
                ? null
                : () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
          );
        }

        if (index == 2) {
          return _LostPetFilters(
            selected: _activeFilter,
            allCount: _countFor(_LostPetFilter.all),
            dogCount: _countFor(_LostPetFilter.dogs),
            catCount: _countFor(_LostPetFilter.cats),
            onSelected: (filter) => setState(() => _activeFilter = filter),
          );
        }

        if (filteredReports.isEmpty) {
          return _EmptyState(hasSearch: _searchQuery.trim().isNotEmpty);
        }

        final report = filteredReports[index - 3];
        return _LostPetCard(
          report: report,
          onTap: () => _openDetail(report),
          onCall: () => _callOwner(report),
        );
      },
    );
  }
}

enum _LostPetFilter { all, dogs, cats }

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.lostPetsTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            '$count pets need help',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.negativeBackgroundDark.withValues(alpha: 0.45)
            : AppColors.overdueCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.smartAlertWarningTextDark
              : AppColors.overdueCardBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: isDark
                ? AppColors.smartAlertWarningTextDark
                : AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.lostPetsHelpTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.smartAlertWarningTextDark
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  AppStrings.lostPetsHelpBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _LostPetFilters extends StatelessWidget {
  const _LostPetFilters({
    required this.selected,
    required this.allCount,
    required this.dogCount,
    required this.catCount,
    required this.onSelected,
  });

  final _LostPetFilter selected;
  final int allCount;
  final int dogCount;
  final int catCount;
  final ValueChanged<_LostPetFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'All ($allCount)',
          selected: selected == _LostPetFilter.all,
          onTap: () => onSelected(_LostPetFilter.all),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        _FilterChipButton(
          label: 'Dogs ($dogCount)',
          selected: selected == _LostPetFilter.dogs,
          onTap: () => onSelected(_LostPetFilter.dogs),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        _FilterChipButton(
          label: 'Cats ($catCount)',
          selected: selected == _LostPetFilter.cats,
          onTap: () => onSelected(_LostPetFilter.cats),
        ),
      ],
    );
  }
}

class _LostPetSearchBar extends StatelessWidget {
  const _LostPetSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name, breed, color or location',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = selected
        ? AppColors.primaryVariant
        : (isDark
              ? AppColors.petCardBackgroundDark
              : AppColors.petCardBackground);
    final textColor = selected
        ? AppColors.primary
        : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LostPetCard extends StatelessWidget {
  const _LostPetCard({
    required this.report,
    required this.onTap,
    required this.onCall,
  });

  final LostPetReportModel report;
  final VoidCallback onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.petCardBackgroundDark
        : AppColors.petCardBackground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: surface,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PetPhoto(photoUrl: report.photoUrl, isDark: isDark),
                      Positioned(
                        left: AppDimensions.spaceM,
                        top: AppDimensions.spaceS,
                        child: _LostBadge(isDark: isDark),
                      ),
                      Positioned(
                        right: AppDimensions.spaceM,
                        top: AppDimensions.spaceM,
                        child: _SeenAgoBadge(report: report),
                      ),
                      Positioned(
                        left: AppDimensions.spaceM,
                        right: AppDimensions.spaceM,
                        bottom: AppDimensions.spaceM,
                        child: _PhotoTitle(report: report),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PetMetaRow(report: report, isDark: isDark),
                      const SizedBox(height: AppDimensions.spaceM),
                      _LocationRow(location: report.lastSeen, isDark: isDark),
                      const SizedBox(height: AppDimensions.spaceM),
                      Divider(
                        color: isDark
                            ? AppColors.bottomNavTopBorderDark
                            : AppColors.bottomNavTopBorder,
                        height: 1,
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      _OwnerCallRow(
                        contact: report.primaryContact,
                        isDark: isDark,
                        onCall: onCall,
                      ),
                    ],
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

class _PhotoTitle extends StatelessWidget {
  const _PhotoTitle({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.petName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            height: 1.05,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(
          report.breed.trim().isEmpty ? report.species : report.breed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.92),
            fontWeight: FontWeight.w500,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _SeenAgoBadge extends StatelessWidget {
  const _SeenAgoBadge({required this.report});

  final LostPetReportModel report;

  @override
  Widget build(BuildContext context) {
    final seenAt =
        report.createdAt ?? report.updatedAt ?? report.lastSeen.seenAt;
    if (seenAt == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 13,
              color: AppColors.onPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatAgo(seenAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours} hr ago';
    }
    final minutes = difference.inMinutes.clamp(1, 59);
    return '$minutes min ago';
  }
}

class _PetMetaRow extends StatelessWidget {
  const _PetMetaRow({required this.report, required this.isDark});

  final LostPetReportModel report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SpeciesBadge(species: report.species, isDark: isDark),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: Text(
            _metaText(report),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _metaText(LostPetReportModel report) {
    final parts = [
      if (report.gender.trim().isNotEmpty) report.gender.trim(),
      if (report.ageLabel.trim().isNotEmpty) report.ageLabel.trim(),
      if (report.weight != null) '${report.weight!.toStringAsFixed(1)} kg',
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(' · ');
  }
}

class _SpeciesBadge extends StatelessWidget {
  const _SpeciesBadge({required this.species, required this.isDark});

  final String species;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = species.trim().isEmpty ? 'Pet' : species.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.quickActionIconBackgroundDark
            : AppColors.primaryVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.quickActionIconTintDark : AppColors.primary,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
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
  const _LostBadge({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.negativeBackgroundDark : AppColors.onPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStrings.petDetailStatusLost,
        style: TextStyle(
          color: isDark ? AppColors.negativeTextDark : AppColors.negativeText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _OwnerCallRow extends StatelessWidget {
  const _OwnerCallRow({
    required this.contact,
    required this.isDark,
    required this.onCall,
  });

  final LostPetContactModel? contact;
  final bool isDark;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final name = contact?.name.trim().isNotEmpty == true
        ? contact!.name.trim()
        : 'Owner';
    final relationship = contact?.relationship.trim().isNotEmpty == true
        ? contact!.relationship.trim()
        : 'Owner';
    final canCall =
        contact?.allowCall == true && contact!.phone.trim().isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isDark
              ? AppColors.quickActionIconBackgroundDark
              : AppColors.primaryVariant,
          foregroundColor: isDark
              ? AppColors.quickActionIconTintDark
              : AppColors.primary,
          child: Text(
            _initials(name),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.grey900,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                relationship,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: canCall ? onCall : null,
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text(AppStrings.lostPetCall),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location, required this.isDark});

  final LostPetLocationModel location;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final text = location.name.trim().isNotEmpty
        ? location.name.trim()
        : 'Bogotá';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardQuickActionBgDark
            : AppColors.petCardQuickActionBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: isDark
                ? AppColors.quickActionIconTintDark
                : AppColors.bottomNavActive,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              '${AppStrings.lostPetLastSeen}: $text',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 56,
              color: AppColors.grey300,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              hasSearch
                  ? 'No lost pets match that search.'
                  : AppStrings.lostPetsEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.lostPetsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
