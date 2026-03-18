import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/app_dropdown_field.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddVaccineStepBasic extends StatelessWidget {
  const AddVaccineStepBasic({
    super.key,
    required this.isLoadingVaccines,
    required this.isLoadingPets,
    required this.selectedVaccineName,
    required this.selectedProductName,
    required this.selectedPetName,
    required this.vaccineNameOptions,
    required this.productOptions,
    required this.petNameOptions,
    required this.onVaccineChanged,
    required this.onProductChanged,
    required this.onPetChanged,
    required this.onPickDate,
    required this.dateController,
  });

  final bool isLoadingVaccines;
  final bool isLoadingPets;
  final String? selectedVaccineName;
  final String? selectedProductName;
  final String? selectedPetName;
  final List<String> vaccineNameOptions;
  final List<String> productOptions;
  final List<String> petNameOptions;
  final ValueChanged<String?> onVaccineChanged;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<String?> onPetChanged;
  final VoidCallback onPickDate;
  final TextEditingController dateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdownField(
          label: '${AppStrings.labelVaccineName} *',
          hintText: isLoadingVaccines
              ? 'Loading vaccines...'
              : AppStrings.hintVaccineName,
          value: selectedVaccineName,
          items: vaccineNameOptions,
          enabled: !isLoadingVaccines,
          onChanged: onVaccineChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: '${AppStrings.labelDate} *',
          hintText: AppStrings.hintDate,
          icon: Icons.calendar_today_outlined,
          controller: dateController,
          readOnly: true,
          onTap: onPickDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationInvalidDate;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: AppStrings.labelProductName,
          hintText: selectedVaccineName == null
              ? 'Select a vaccine first'
              : productOptions.isEmpty
                  ? 'No products available'
                  : AppStrings.hintProductName,
          value: selectedProductName,
          items: productOptions,
          enabled: selectedVaccineName != null && productOptions.isNotEmpty,
          onChanged: onProductChanged,
          validator: (value) {
            if (productOptions.isEmpty) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: AppStrings.labelPetName,
          hintText:
              isLoadingPets ? 'Loading pets...' : AppStrings.hintPetName,
          value: selectedPetName,
          items: petNameOptions,
          enabled: !isLoadingPets && petNameOptions.isNotEmpty,
          onChanged: onPetChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
