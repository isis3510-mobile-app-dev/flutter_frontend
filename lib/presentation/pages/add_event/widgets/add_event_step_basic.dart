import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepBasic extends StatelessWidget {
  const AddEventStepBasic({
    super.key,
    required this.eventController,
    required this.dateController,
    required this.timeController,
    required this.petNameController,
    required this.onPickDate,
    required this.onPickTime,
  });

  final TextEditingController eventController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController petNameController;
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
          onTap: onPickTime,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.validationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelPetName,
          hintText: AppStrings.hintPetName,
          controller: petNameController,
        ),
      ],
    );
  }
}
