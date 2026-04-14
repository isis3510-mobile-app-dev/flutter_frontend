import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/forms/app_form_constraints.dart';
import '../../../../../core/forms/app_form_utils.dart';
import '../widgets/pet_form_field.dart';

class StepMedical extends StatelessWidget {
  const StepMedical({
    super.key,
    required this.veterinarianController,
    required this.clinicController,
    required this.allergiesController,
  });

  final TextEditingController veterinarianController;
  final TextEditingController clinicController;
  final TextEditingController allergiesController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final almostDoneBackground = isDark
        ? AppColors.addPetPhotoBackgroundDark
        : AppColors.addPetPhotoBackground;
    final almostDoneTitleColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.addPetBannerText;
    final almostDoneBodyColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.84)
        : AppColors.addPetBannerText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: almostDoneBackground,
            borderRadius: BorderRadius.circular(18),
            border: isDark ? Border.all(color: AppColors.grey700) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.addPetAlmostDoneTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: almostDoneTitleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                AppStrings.addPetAlmostDoneMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: almostDoneBodyColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXL),
        PetFormField(
          label: AppStrings.addPetVeterinarianLabel,
          controller: veterinarianController,
          hintText: AppStrings.addPetVeterinarianHint,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.providerNameMaxLength,
            ),
          ],
          validator: AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.addPetVeterinarianLabel,
            maxLength: AppFormConstraints.providerNameMaxLength,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetClinicLabel,
          controller: clinicController,
          hintText: AppStrings.addPetClinicHint,
          inputFormatters: AppInputFormatters.safeSingleLineText(
            AppFormConstraints.clinicNameMaxLength,
          ),
          validator: AppFormValidators.safeSingleLineText(
            fieldLabel: AppStrings.addPetClinicLabel,
            maxLength: AppFormConstraints.clinicNameMaxLength,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetAllergiesLabel,
          controller: allergiesController,
          hintText: AppStrings.addPetAllergiesHint,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.allergiesMaxLength,
            ),
          ],
          validator: AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.addPetAllergiesLabel,
            maxLength: AppFormConstraints.allergiesMaxLength,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXL),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.addPetReminderBackgroundDark
                : AppColors.addPetReminderBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/featureIcons/nfc.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  AppColors.bottomNavActive,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.addPetNfcTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      AppStrings.addPetNfcMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceDark.withValues(alpha: 0.82)
                            : AppColors.grey700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
