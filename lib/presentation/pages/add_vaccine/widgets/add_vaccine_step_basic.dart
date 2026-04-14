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
    required this.selectedVaccineId,
    required this.selectedPetName,
    required this.selectedPetId,
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
  final String? selectedVaccineId;
  final String? selectedPetName;
  final String? selectedPetId;
  final List<String> vaccineNameOptions;
  final List<String> productOptions;
  final List<String> petNameOptions;
  final ValueChanged<String?> onVaccineChanged;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<String?> onPetChanged;
  final VoidCallback onPickDate;
  final TextEditingController dateController;

  bool _isValidDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return false;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    return day != null &&
        month != null &&
        year != null &&
        DateTime.tryParse(
              '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
            ) !=
            null;
  }

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
              return AppStrings.validationSelectVaccine;
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
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty || !_isValidDate(trimmed)) {
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
              return AppStrings.validationSelectProduct;
            }
            if ((selectedVaccineId?.trim() ?? '').isEmpty) {
              return AppStrings.validationSelectProduct;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: AppStrings.labelPetName,
          hintText: isLoadingPets ? 'Loading pets...' : AppStrings.hintPetName,
          value: selectedPetName,
          items: petNameOptions,
          enabled: !isLoadingPets && petNameOptions.isNotEmpty,
          onChanged: onPetChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationSelectPet;
            }
            if ((selectedPetId?.trim() ?? '').isEmpty) {
              return AppStrings.validationSelectValidPet;
            }
            return null;
          },
        ),
      ],
    );
  }
}
