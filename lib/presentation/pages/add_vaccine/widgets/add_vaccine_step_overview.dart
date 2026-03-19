import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddVaccineStepOverview extends StatelessWidget {
  const AddVaccineStepOverview({
    super.key,
    required this.vaccineController,
    required this.dateController,
    required this.productController,
    required this.petNameController,
    required this.administeredByController,
    required this.attachmentNames,
  });

  final TextEditingController vaccineController;
  final TextEditingController dateController;
  final TextEditingController productController;
  final TextEditingController petNameController;
  final TextEditingController administeredByController;
  final List<String> attachmentNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: AppStrings.labelVaccineName,
          hintText: AppStrings.hintNotProvided,
          controller: vaccineController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelDate,
          hintText: AppStrings.hintNotProvided,
          controller: dateController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelProductName,
          hintText: AppStrings.hintNotProvided,
          controller: productController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelPetName,
          hintText: AppStrings.hintNotProvided,
          controller: petNameController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelAdministeredBy,
          hintText: AppStrings.hintNotProvided,
          controller: administeredByController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelAdditionalFiles,
          hintText: attachmentNames.isEmpty
              ? AppStrings.vaccineNoDocuments
              : attachmentNames.join(', '),
          controller: TextEditingController(
            text: attachmentNames.isEmpty ? '' : attachmentNames.join(', '),
          ),
          readOnly: true,
        ),
      ],
    );
  }
}
