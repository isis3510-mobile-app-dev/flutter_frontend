import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/forms/app_form_constraints.dart';
import '../../../../../core/forms/app_form_utils.dart';
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

  bool _isValidPastDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return false;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return false;
    }

    final parsed = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );

    return parsed != null && !parsed.isAfter(DateTime.now());
  }

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
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return AppStrings.validationFieldRequired(
                AppStrings.addPetDobLabel,
              );
            }
            if (!_isValidPastDate(trimmed)) {
              return AppStrings.validationInvalidDate;
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spaceL),
        FormField<PetGender>(
          initialValue: gender,
          validator: (value) {
            if (value == null) {
              return AppStrings.validationGenderRequired;
            }
            return null;
          },
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    onTap: () {
                      field.didChange(PetGender.male);
                      onGenderSelected(PetGender.male);
                    },
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
                    onTap: () {
                      field.didChange(PetGender.female);
                      onGenderSelected(PetGender.female);
                    },
                  ),
                ],
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
          label: AppStrings.addPetWeightLabel,
          controller: weightController,
          hintText: AppStrings.addPetWeightHint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: AppInputFormatters.decimal(
            maxWholeDigits: 2,
            decimalDigits: 1,
          ),
          validator: AppFormValidators.optionalDecimal(
            invalidMessage: AppStrings.validationInvalidNumber,
            maxValue: AppFormConstraints.petWeightMaxKg,
            maxMessage: AppStrings.validationPetWeightMax,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetColorLabel,
          controller: colorController,
          hintText: AppStrings.addPetColorHint,
          inputFormatters: AppInputFormatters.safeSingleLineText(
            AppFormConstraints.colorMaxLength,
          ),
          validator: AppFormValidators.safeSingleLineText(
            fieldLabel: AppStrings.addPetColorLabel,
            maxLength: AppFormConstraints.colorMaxLength,
          ),
        ),
      ],
    );
  }
}
