import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum PetFilter { all, healthy, vaccineDue, lost }

extension PetFilterLabel on PetFilter {
  String get label => switch (this) {
    PetFilter.all => 'All Pets',
    PetFilter.healthy => 'Healthy',
    PetFilter.vaccineDue => 'Vaccine Due',
    PetFilter.lost => 'Lost',
  };
}

class PetFilterChips extends StatelessWidget {
  const PetFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PetFilter selected;
  final ValueChanged<PetFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: PetFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: filter.label,
              isActive: filter == selected,
              onTap: () => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.bottomNavActive
              : (isDark
                    ? AppColors.petCardBackgroundDark
                    : AppColors.petCardBackground),
          borderRadius: BorderRadius.circular(999),
          border: isActive
              ? null
              : const Border.fromBorderSide(
                  BorderSide(color: AppColors.petFilterInactiveBorder),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.onSurfaceDark : AppColors.grey700),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
