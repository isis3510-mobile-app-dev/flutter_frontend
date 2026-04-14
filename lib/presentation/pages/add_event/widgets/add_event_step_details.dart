import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
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
          inputFormatters: AppInputFormatters.decimal(
            maxWholeDigits: 6,
            decimalDigits: 2,
          ),
          validator: AppFormValidators.optionalDecimal(
            invalidMessage: AppStrings.validationInvalidNumber,
            maxValue: AppFormConstraints.eventPriceMax,
            maxMessage: AppStrings.validationPriceMax,
          ),
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventProvider,
          hintText: AppStrings.hintEventProvider,
          controller: providerController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.providerNameMaxLength,
            ),
          ],
          validator: AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.labelEventProvider,
            maxLength: AppFormConstraints.providerNameMaxLength,
          ),
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventClinic,
          hintText: AppStrings.hintEventClinic,
          controller: clinicController,
          inputFormatters: AppInputFormatters.safeSingleLineText(
            AppFormConstraints.clinicNameMaxLength,
          ),
          validator: AppFormValidators.safeSingleLineText(
            fieldLabel: AppStrings.labelEventClinic,
            maxLength: AppFormConstraints.clinicNameMaxLength,
          ),
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelEventFollowUpDate,
          hintText: AppStrings.hintDate,
          icon: Icons.calendar_today_outlined,
          controller: followUpDateController,
          readOnly: true,
          onTap: onPickFollowUpDate,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty || _isValidDate(trimmed)) {
              return null;
            }
            return AppStrings.validationInvalidDate;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: AppStrings.labelDescription,
          hintText: AppStrings.hintEventDescription,
          controller: descriptionController,
          maxLines: 4,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.eventDescriptionMaxLength,
            ),
          ],
          validator: AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.labelDescription,
            maxLength: AppFormConstraints.eventDescriptionMaxLength,
          ),
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
