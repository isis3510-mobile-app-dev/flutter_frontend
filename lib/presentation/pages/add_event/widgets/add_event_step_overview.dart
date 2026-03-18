import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepOverview extends StatelessWidget {
  const AddEventStepOverview({
    super.key,
    required this.eventController,
    required this.dateController,
    required this.timeController,
    required this.petNameController,
    required this.descriptionController,
  });

  final TextEditingController eventController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController petNameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: AppStrings.labelEventName,
          hintText: AppStrings.hintNotProvided,
          controller: eventController,
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
          label: AppStrings.labelEventTime,
          hintText: AppStrings.hintNotProvided,
          controller: timeController,
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
          label: AppStrings.labelDescription,
          hintText: AppStrings.hintNotProvided,
          controller: descriptionController,
          readOnly: true,
        ),
      ],
    );
  }
}
