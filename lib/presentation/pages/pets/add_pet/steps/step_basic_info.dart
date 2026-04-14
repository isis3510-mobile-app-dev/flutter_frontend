import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/forms/app_form_constraints.dart';
import '../../../../../core/forms/app_form_utils.dart';
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
    required this.onRemovePhoto,
    this.imagePath,
  });

  final TextEditingController nameController;
  final TextEditingController breedController;
  final PetSpecies? species;
  final ValueChanged<PetSpecies> onSpeciesSelected;
  final VoidCallback onPhotoTap;
  final VoidCallback onRemovePhoto;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spaceM),
        PetPhotoPicker(
          onTap: onPhotoTap,
          onRemovePhoto: onRemovePhoto,
          imagePath: imagePath,
        ),
        const SizedBox(height: AppDimensions.spaceXXL),
        PetFormField(
          label: '${AppStrings.addPetNameLabel} *',
          controller: nameController,
          hintText: AppStrings.addPetNameHint,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.petNameMaxLength,
            ),
          ],
          validator: AppFormValidators.combine([
            AppFormValidators.required(
              AppStrings.validationFieldRequired(AppStrings.addPetNameLabel),
            ),
            AppFormValidators.maxCharacters(
              fieldLabel: AppStrings.addPetNameLabel,
              maxLength: AppFormConstraints.petNameMaxLength,
            ),
          ]),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        FormField<PetSpecies>(
          initialValue: species,
          validator: (value) {
            if (value == null) {
              return AppStrings.validationSpeciesRequired;
            }
            return null;
          },
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.addPetSpeciesLabel} *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              SpeciesSelector(
                selected: species,
                onSelected: (selectedSpecies) {
                  field.didChange(selectedSpecies);
                  onSpeciesSelected(selectedSpecies);
                },
              ),
              if (field.hasError) ...[
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  field.errorText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetBreedLabel,
          controller: breedController,
          hintText: AppStrings.addPetBreedHint,
          inputFormatters: AppInputFormatters.safeSingleLineText(
            AppFormConstraints.breedMaxLength,
          ),
          validator: AppFormValidators.safeSingleLineText(
            fieldLabel: AppStrings.addPetBreedLabel,
            maxLength: AppFormConstraints.breedMaxLength,
          ),
        ),
      ],
    );
  }
}
