import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_attachments.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddVaccineStepDetails extends StatelessWidget {
  const AddVaccineStepDetails({
    super.key,
    required this.administeredByController,
  });

  final TextEditingController administeredByController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: AppStrings.labelAdministeredBy,
          hintText: AppStrings.hintAdministeredBy,
          controller: administeredByController,
        ),
        const SizedBox(height: 18),
        const AddFlowAttachmentsSection(),
      ],
    );
  }
}
