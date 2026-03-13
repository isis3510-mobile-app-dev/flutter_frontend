import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../add_pet_form_types.dart';
import '../widgets/pet_form_field.dart';

class StepDetails extends StatelessWidget {
  const StepDetails({
    super.key,
    required this.dateOfBirthController,
    required this.weightController,
    required this.colorController,
    required this.gender,
    required this.onPickDate,
    required this.onGenderSelected,
  });

  final TextEditingController dateOfBirthController;
  final TextEditingController weightController;
  final TextEditingController colorController;
  final PetGender? gender;
  final VoidCallback onPickDate;
  final ValueChanged<PetGender> onGenderSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PetFormField(
          label: '${AppStrings.addPetDobLabel} *',
          controller: dateOfBirthController,
          hintText: AppStrings.addPetDobHint,
          readOnly: true,
          onTap: onPickDate,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.addPetValidationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Text(
          '${AppStrings.addPetGenderLabel} *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        SegmentedButton<PetGender>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: PetGender.male,
              label: Text(AppStrings.addPetGenderMale),
            ),
            ButtonSegment(
              value: PetGender.female,
              label: Text(AppStrings.addPetGenderFemale),
            ),
          ],
          selected: gender == null ? const {} : {gender!},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onGenderSelected(selection.first);
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.bottomNavActive;
              }
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppColors.grey700;
            }),
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.selected)
                    ? AppColors.bottomNavActive
                    : AppColors.grey300,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetWeightLabel,
          controller: weightController,
          hintText: AppStrings.addPetWeightHint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetColorLabel,
          controller: colorController,
          hintText: AppStrings.addPetColorHint,
        ),
      ],
    );
  }
}
