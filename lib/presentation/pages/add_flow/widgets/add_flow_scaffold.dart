import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/presentation/widgets/stepper.dart' as app_stepper;
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class AddFlowScaffold extends StatelessWidget {
  const AddFlowScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.steps,
    required this.currentStep,
    required this.stepContent,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    required this.onBackPressed,
    this.backButtonText = 'Back',
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<String> steps;
  final int currentStep;
  final List<Widget> stepContent;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onBackPressed;
  final String backButtonText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                app_stepper.Stepper(
                  steps: steps,
                  currentStep: currentStep,
                ),
                const SizedBox(height: 28),
                ...stepContent,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 24, right: 24, bottom: 60),
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: FullWidthButton(
                    text: backButtonText,
                    onPressed: onBackPressed,
                    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderColor: AppColors.primary,
                    textColor: AppColors.primary,
                  ),
                ),
              if (currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: FullWidthButton(
                  text: primaryButtonText,
                  onPressed: onPrimaryPressed,
                  backgroundColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  textColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
