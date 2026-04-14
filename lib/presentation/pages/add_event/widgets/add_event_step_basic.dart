import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/app_dropdown_field.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepBasic extends StatelessWidget {
  const AddEventStepBasic({
    super.key,
    required this.isLoadingPets,
    required this.selectedPetName,
    required this.selectedPetId,
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
  final String? selectedPetId;
  final List<String> petNameOptions;
  final ValueChanged<String?> onPetChanged;
  final TextEditingController eventController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

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

  bool _isValidTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return false;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: '${AppStrings.labelEventName} *',
          hintText: AppStrings.hintEventName,
          controller: eventController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.eventTitleMaxLength,
            ),
          ],
          validator: AppFormValidators.combine([
            AppFormValidators.required(
              AppStrings.validationFieldRequired(AppStrings.labelEventName),
            ),
            AppFormValidators.maxCharacters(
              fieldLabel: AppStrings.labelEventName,
              maxLength: AppFormConstraints.eventTitleMaxLength,
            ),
          ]),
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
        AppFormField(
          label: AppStrings.labelEventTime,
          hintText: AppStrings.hintEventTime,
          controller: timeController,
          readOnly: true,
          onTap: onPickTime,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty || !_isValidTime(trimmed)) {
              return 'Enter a valid time (HH:mm).';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: '${AppStrings.labelPetName} *',
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
