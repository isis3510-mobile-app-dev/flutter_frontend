import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../add_pet_form_types.dart';

class SpeciesSelector extends StatelessWidget {
  const SpeciesSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PetSpecies? selected;
  final ValueChanged<PetSpecies> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpeciesChip(
            label: AppStrings.addPetSpeciesDog,
            isSelected: selected == PetSpecies.dog,
            onTap: () => onSelected(PetSpecies.dog),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _SpeciesChip(
            label: AppStrings.addPetSpeciesCat,
            isSelected: selected == PetSpecies.cat,
            onTap: () => onSelected(PetSpecies.cat),
          ),
        ),
      ],
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  const _SpeciesChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: SizedBox(
        width: double.infinity,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isSelected ? Colors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        side: BorderSide(
          color: isSelected ? AppColors.bottomNavActive : AppColors.grey300,
        ),
      ),
      showCheckmark: false,
      selectedColor: AppColors.bottomNavActive,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }
}
