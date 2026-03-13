import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../widgets/info_banner.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoBanner(
          title: AppStrings.addPetAlmostDoneTitle,
          message: AppStrings.addPetAlmostDoneMessage,
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: AppDimensions.spaceXL),
        PetFormField(
          label: AppStrings.addPetVeterinarianLabel,
          controller: veterinarianController,
          hintText: AppStrings.addPetVeterinarianHint,
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetClinicLabel,
          controller: clinicController,
          hintText: AppStrings.addPetClinicHint,
        ),
        const SizedBox(height: AppDimensions.spaceL),
        PetFormField(
          label: AppStrings.addPetAllergiesLabel,
          controller: allergiesController,
          hintText: AppStrings.addPetAllergiesHint,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimensions.spaceXL),
        const InfoBanner(
          title: AppStrings.addPetNfcTitle,
          message: AppStrings.addPetNfcMessage,
          icon: Icons.nfc_rounded,
        ),
      ],
    );
  }
}
