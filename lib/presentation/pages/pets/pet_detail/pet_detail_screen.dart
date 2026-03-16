import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/quick_actions_fab.dart';
import '../models/pet_ui_model.dart';
import 'tabs/events_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/vaccines_tab.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key, required this.pet});

  final PetUiModel pet;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.background,
        body: Column(
          children: [
            _PetDetailHeader(
              pet: widget.pet,
              onBack: () => Navigator.pop(context),
              onShare: () {},
              onEdit: () {},
              onMore: () {},
            ),
            _PetDetailTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(pet: widget.pet),
                  VaccinesTab(pet: widget.pet),
                  EventsTab(pet: widget.pet),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: QuickActionsFab(
          onAddPet: () {},
          onAddVaccine: () {},
          onAddEvent: () {},
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PetDetailHeader extends StatelessWidget {
  const _PetDetailHeader({
    required this.pet,
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onMore,
  });

  final PetUiModel pet;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.petDetailHeaderBg,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background circle
            Positioned(
              right: -30,
              top: -96,
              child: Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bottomNavActive.withValues(alpha: 0.45),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActionBar(
                  onBack: onBack,
                  onShare: onShare,
                  onEdit: onEdit,
                  onMore: onMore,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceXS,
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceL,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PetPhoto(photoUrl: pet.photoUrl, species: pet.species),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(child: _PetInfo(pet: pet)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onMore,
  });

  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            tooltip: AppStrings.semanticBackButton,
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.ios_share_outlined,
              color: Colors.white,
              size: 20,
            ),
            tooltip: AppStrings.petDetailShareSemantics,
            onPressed: onShare,
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
            tooltip: AppStrings.petDetailEditSemantics,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            tooltip: AppStrings.petDetailMoreSemantics,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.photoUrl, required this.species});

  final String? photoUrl;
  final String species;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PhotoPlaceholder(species: species),
            )
          : _PhotoPlaceholder(species: species),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) {
    final assetName = species.toLowerCase() == 'cat'
        ? 'catSecondary'
        : 'dogSecondary';
    return ColoredBox(
      color: AppColors.bottomNavActive.withValues(alpha: 0.6),
      child: Center(
        child: Image.asset(
          'assets/images/$assetName.png',
          width: 46,
          height: 46,
          errorBuilder: (_, _, _) => SvgPicture.asset(
            'assets/icons/featureIcons/pets.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _PetInfo extends StatelessWidget {
  const _PetInfo({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatusBadge(status: pet.status),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Image.asset(
              pet.species.toLowerCase() == 'cat'
                  ? 'assets/images/catPrimary.png'
                  : 'assets/images/dogPrimary.png',
              width: 14,
              height: 14,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '${pet.breed} · ${pet.species}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PetMetaRow(pet: pet),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (status) {
      'healthy' => AppColors.petStatusHealthyBg,
      'lost' => AppColors.petStatusLostBg,
      _ => AppColors.petStatusAttentionBg,
    };
    final textColor = switch (status) {
      'healthy' => AppColors.petStatusHealthyText,
      'lost' => AppColors.petStatusLostText,
      _ => AppColors.petStatusAttentionText,
    };
    final label = switch (status) {
      'healthy' => AppStrings.petDetailStatusHealthy,
      'lost' => AppStrings.petDetailStatusLost,
      _ => AppStrings.petDetailStatusNeedsAttention,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _PetMetaRow extends StatelessWidget {
  const _PetMetaRow({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final genderIcon = pet.gender.toLowerCase() == 'female'
        ? 'assets/icons/petRelated/female.svg'
        : 'assets/icons/petRelated/male.svg';

    return Row(
      children: [
        _MetaItem(
          iconPath: 'assets/icons/petRelated/age.svg',
          label: pet.ageLabel,
        ),
        const SizedBox(width: 14),
        _MetaItem(
          iconPath: 'assets/icons/petRelated/weight.svg',
          label: pet.weightLabel,
        ),
        const SizedBox(width: 14),
        _MetaItem(iconPath: genderIcon, label: pet.gender),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.iconPath, required this.label});

  final String iconPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.85),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Tab Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PetDetailTabBar extends StatelessWidget {
  const _PetDetailTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Row(
              children: [
                _Tab(
                  label: AppStrings.petDetailTabOverview,
                  svgPath: 'assets/icons/featureIcons/overview.svg',
                  isActive: controller.index == 0,
                  onTap: () => controller.animateTo(0),
                ),
                _Tab(
                  label: AppStrings.petDetailTabVaccines,
                  svgPath: 'assets/icons/featureIcons/vaccines.svg',
                  isActive: controller.index == 1,
                  onTap: () => controller.animateTo(1),
                ),
                _Tab(
                  label: AppStrings.petDetailTabEvents,
                  svgPath: 'assets/icons/featureIcons/calendar.svg',
                  isActive: controller.index == 2,
                  onTap: () => controller.animateTo(2),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.petFilterInactiveBorder,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.svgPath,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String svgPath;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.bottomNavActive
        : AppColors.bottomNavInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    svgPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2.5,
              color: isActive ? AppColors.bottomNavActive : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
