import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_attachments.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddVaccineStepDetails extends StatelessWidget {
  const AddVaccineStepDetails({
    super.key,
    required this.administeredByController,
    required this.onAddAttachment,
    required this.attachments,
    required this.onRemoveAttachment,
    this.onRetryAttachment,
  });

  final TextEditingController administeredByController;
  final VoidCallback onAddAttachment;
  final List<AttachmentUploadItem> attachments;
  final ValueChanged<String> onRemoveAttachment;
  final ValueChanged<String>? onRetryAttachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: AppStrings.labelAdministeredBy,
          hintText: AppStrings.hintAdministeredBy,
          controller: administeredByController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              AppFormConstraints.administeredByMaxLength,
            ),
          ],
          validator: AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.labelAdministeredBy,
            maxLength: AppFormConstraints.administeredByMaxLength,
          ),
        ),
        const SizedBox(height: 18),
        AddFlowAttachmentsSection(
          onTap: onAddAttachment,
          attachments: attachments,
          onRemoveAttachment: onRemoveAttachment,
          onRetryAttachment: onRetryAttachment,
        ),
      ],
    );
  }
}
