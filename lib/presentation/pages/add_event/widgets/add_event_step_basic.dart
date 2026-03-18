import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/app_dropdown_field.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepBasic extends StatelessWidget {
  const AddEventStepBasic({
    super.key,
    required this.isLoadingPets,
    required this.selectedPetName,
    required this.petNameOptions,
    required this.onPetChanged,
    required this.eventController,
    required this.dateController,
    required this.timeController,
    required this.onPickDate,
    required this.onPickTime,
  });

  final bool isLoadingPets;
  final String? selectedPetName;
  final List<String> petNameOptions;
  final ValueChanged<String?> onPetChanged;
  final TextEditingController eventController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: '${AppStrings.labelEventName} *',
          hintText: AppStrings.hintEventName,
          controller: eventController,
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
        AppFormField(
          label: AppStrings.labelEventTime,
          hintText: AppStrings.hintEventTime,
          controller: timeController,
          readOnly: true,
          onTap: onPickTime,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: '${AppStrings.labelPetName} *',
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
