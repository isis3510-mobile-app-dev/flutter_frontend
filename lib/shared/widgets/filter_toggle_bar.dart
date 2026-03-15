import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';

class FilterToggleBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FilterOption> filters;

  const FilterToggleBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(filters.length, (index) {
        final filter = filters[index];
        final isSelected = index == selectedIndex;

        return _FilterChip(
          label: filter.label,
          icon: filter.icon,
          isSelected: isSelected,
          onTap: () => onSelected(index),
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isSelected ? AppColors.onPrimary : AppColors.grey900;
    final backgroundColor = isSelected ? AppColors.primary : AppColors.secondary;
    final borderColor = isSelected ? AppColors.primary : AppColors.grey500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        splashColor: AppColors.primaryVariant,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model
class FilterOption {
  final String label;
  final IconData icon;
  const FilterOption({required this.label, required this.icon});
}
