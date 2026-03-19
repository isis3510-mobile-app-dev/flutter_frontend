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
    required this.eventTypeController,
    required this.priceController,
    required this.providerController,
    required this.clinicController,
    required this.followUpDateController,
    required this.descriptionController,
    required this.attachmentNames,
  });

  final TextEditingController eventController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController petNameController;
  final TextEditingController eventTypeController;
  final TextEditingController priceController;
  final TextEditingController providerController;
  final TextEditingController clinicController;
  final TextEditingController followUpDateController;
  final TextEditingController descriptionController;
  final List<String> attachmentNames;

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
          label: AppStrings.labelEventType,
          hintText: AppStrings.hintNotProvided,
          controller: eventTypeController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventPrice,
          hintText: AppStrings.hintNotProvided,
          controller: priceController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventProvider,
          hintText: AppStrings.hintNotProvided,
          controller: providerController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventClinic,
          hintText: AppStrings.hintNotProvided,
          controller: clinicController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventFollowUpDate,
          hintText: AppStrings.hintNotProvided,
          controller: followUpDateController,
          readOnly: true,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelDescription,
          hintText: AppStrings.hintNotProvided,
          controller: descriptionController,
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
