import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_attachments.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepDetails extends StatelessWidget {
  const AddEventStepDetails({
    super.key,
    required this.eventController,
    required this.priceController,
    required this.providerController,
    required this.clinicController,
    required this.followUpDateController,
    required this.onPickFollowUpDate,
    required this.descriptionController,
    required this.onAddAttachment,
    required this.attachmentNames,
    required this.onRemoveAttachment,
    required this.isUploadingAttachments,
  });

  final TextEditingController eventController;
  final TextEditingController priceController;
  final TextEditingController providerController;
  final TextEditingController clinicController;
  final TextEditingController followUpDateController;
  final VoidCallback onPickFollowUpDate;
  final TextEditingController descriptionController;
  final VoidCallback onAddAttachment;
  final List<String> attachmentNames;
  final ValueChanged<int> onRemoveAttachment;
  final bool isUploadingAttachments;

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
          label: AppStrings.labelEventPrice,
          hintText: AppStrings.hintEventPrice,
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null;
            }

            final normalizedValue = value.trim().replaceAll(',', '.');
            if (double.tryParse(normalizedValue) == null) {
              return AppStrings.validationInvalidNumber;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventProvider,
          hintText: AppStrings.hintEventProvider,
          controller: providerController,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventClinic,
          hintText: AppStrings.hintEventClinic,
          controller: clinicController,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventFollowUpDate,
          hintText: AppStrings.hintDate,
          icon: Icons.calendar_today_outlined,
          controller: followUpDateController,
          readOnly: true,
          onTap: onPickFollowUpDate,
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelDescription,
          hintText: AppStrings.hintEventDescription,
          controller: descriptionController,
        ),
        const SizedBox(height: 18),
        AddFlowAttachmentsSection(
          onTap: onAddAttachment,
          attachments: attachmentNames,
          onRemoveAttachment: onRemoveAttachment,
          isUploading: isUploadingAttachments,
        ),
      ],
    );
  }
}
