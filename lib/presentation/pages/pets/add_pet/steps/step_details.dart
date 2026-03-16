import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../add_pet_form_types.dart';
import '../widgets/pet_form_field.dart';
import '../widgets/selection_pill.dart';

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
        Row(
          children: [
            SelectionPill(
              label: AppStrings.addPetGenderMale,
              isSelected: gender == PetGender.male,
              expand: true,
              minWidth: 0,
              horizontalPadding: 12,
              verticalPadding: 10,
              iconSpacing: 4,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: gender == PetGender.male
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.onSurfaceDark
                          : AppColors.grey700),
                fontWeight: FontWeight.w600,
              ),
              icon: SvgPicture.asset(
                'assets/icons/petRelated/male.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  gender == PetGender.male
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey700),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onGenderSelected(PetGender.male),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            SelectionPill(
              label: AppStrings.addPetGenderFemale,
              isSelected: gender == PetGender.female,
              expand: true,
              minWidth: 0,
              horizontalPadding: 12,
              verticalPadding: 10,
              iconSpacing: 4,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: gender == PetGender.female
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.onSurfaceDark
                          : AppColors.grey700),
                fontWeight: FontWeight.w600,
              ),
              icon: SvgPicture.asset(
                'assets/icons/petRelated/female.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  gender == PetGender.female
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey700),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onGenderSelected(PetGender.female),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetWeightLabel,
          controller: weightController,
          hintText: AppStrings.addPetWeightHint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
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
