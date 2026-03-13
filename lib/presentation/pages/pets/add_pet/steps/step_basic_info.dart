import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../add_pet_form_types.dart';
import '../widgets/pet_form_field.dart';
import '../widgets/pet_photo_picker.dart';
import '../widgets/species_selector.dart';

class StepBasicInfo extends StatelessWidget {
  const StepBasicInfo({
    super.key,
    required this.nameController,
    required this.breedController,
    required this.species,
    required this.onSpeciesSelected,
    required this.onPhotoTap,
  });

  final TextEditingController nameController;
  final TextEditingController breedController;
  final PetSpecies? species;
  final ValueChanged<PetSpecies> onSpeciesSelected;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PetPhotoPicker(onTap: onPhotoTap),
        const SizedBox(height: AppDimensions.spaceXL),
        PetFormField(
          label: '${AppStrings.addPetNameLabel} *',
          controller: nameController,
          hintText: AppStrings.addPetNameHint,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.addPetValidationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Text(
          '${AppStrings.addPetSpeciesLabel} *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        SpeciesSelector(selected: species, onSelected: onSpeciesSelected),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetBreedLabel,
          controller: breedController,
          hintText: AppStrings.addPetBreedHint,
        ),
      ],
    );
  }
}
