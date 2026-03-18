import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_attachments.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddEventStepDetails extends StatelessWidget {
  const AddEventStepDetails({
    super.key,
    required this.descriptionController,
  });

  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: AppStrings.labelDescription,
          hintText: AppStrings.hintEventDescription,
          controller: descriptionController,
        ),
        const SizedBox(height: 18),
        const AddFlowAttachmentsSection(),
      ],
    );
  }
}
