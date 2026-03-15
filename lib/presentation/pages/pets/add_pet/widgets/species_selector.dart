import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../add_pet_form_types.dart';
import 'selection_pill.dart';

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
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionPill(
          label: AppStrings.addPetSpeciesDog,
          isSelected: selected == PetSpecies.dog,
          icon: Image.asset(
            selected == PetSpecies.dog
                ? 'assets/images/dogSecondary.png'
                : 'assets/images/dogPrimary.png',
            width: 18,
            height: 18,
          ),
          onTap: () => onSelected(PetSpecies.dog),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        SelectionPill(
          label: AppStrings.addPetSpeciesCat,
          isSelected: selected == PetSpecies.cat,
          icon: Image.asset(
            selected == PetSpecies.cat
                ? 'assets/images/catSecondary.png'
                : 'assets/images/catPrimary.png',
            width: 18,
            height: 18,
          ),
          onTap: () => onSelected(PetSpecies.cat),
        ),
      ],
    );
  }
}
