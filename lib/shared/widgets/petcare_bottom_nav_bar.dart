import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';

class PetcareBottomNavBar extends StatelessWidget {
  const PetcareBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = _navItems;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBackground,
        border: Border(
          top: BorderSide(color: AppColors.bottomNavTopBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return Expanded(
                child: _NavBarItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.bottomNavActive
        : AppColors.bottomNavInactive;
    final useActiveAsset = isActive && item.activeAssetPath != null;
    final assetPath = useActiveAsset ? item.activeAssetPath! : item.assetPath;
    final iconColor = useActiveAsset ? null : color;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavIcon(assetPath: assetPath, color: iconColor),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: 22,
      height: 22,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => Icon(
        Icons.circle,
        size: 22,
        color: color ?? AppColors.bottomNavActive,
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.assetPath,
    this.activeAssetPath,
  });

  final String label;
  final String assetPath;
  final String? activeAssetPath;
}

const List<_NavItem> _navItems = [
  _NavItem(
    label: 'Home',
    assetPath: 'assets/icons/featureIcons/home.svg',
    activeAssetPath: 'assets/icons/featureIcons/homeSecondary.svg',
  ),
  _NavItem(
    label: 'Pets',
    assetPath: 'assets/icons/featureIcons/pets.svg',
    activeAssetPath: 'assets/icons/featureIcons/petsSecondary.svg',
  ),
  _NavItem(
    label: 'Records',
    assetPath: 'assets/icons/featureIcons/records.svg',
    activeAssetPath: 'assets/icons/featureIcons/recordsSecondary.svg',
  ),
  _NavItem(
    label: 'Calendar',
    assetPath: 'assets/icons/featureIcons/calendar.svg',
    activeAssetPath: 'assets/icons/featureIcons/calendarSecondary.svg',
  ),
  _NavItem(
    label: 'Profile',
    assetPath: 'assets/icons/featureIcons/profile.svg',
    activeAssetPath: 'assets/icons/featureIcons/profileSecondary.svg',
  ),
];
