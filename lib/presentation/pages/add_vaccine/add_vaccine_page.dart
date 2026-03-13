import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/widgets/stepper.dart' as app_stepper;
import 'package:flutter_frontend/shared/widgets/form_field.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class AddVaccinePage extends StatefulWidget {
  const AddVaccinePage({super.key});

  @override
  State<AddVaccinePage> createState() => _AddVaccinePageState();
}

class _AddVaccinePageState extends State<AddVaccinePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _vaccineController = TextEditingController();
  final _productController = TextEditingController();
  final _notesController = TextEditingController();
  final _petNameController = TextEditingController();
  final _administeredByController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _dateController.dispose();
    _vaccineController.dispose();
    _productController.dispose();
    _notesController.dispose();
    _petNameController.dispose();
    _administeredByController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    final day = pickedDate.day.toString().padLeft(2, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final year = pickedDate.year.toString();
    _dateController.text = '$day/$month/$year';
  }

  void _continue() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      if (_step < 2) {
        _step++;
      }
    });
  }

  void _back() {
    setState(() {
      if (_step > 0) {
        _step--;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample vaccine form submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepContent = _buildStepContent();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addVaccineTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                app_stepper.Stepper(
                  steps: [
                    AppStrings.stepBasicInfo,
                    AppStrings.stepDetails,
                    AppStrings.stepOverview
                  ],
                  currentStep: _step,
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
              if (_step > 0)
                Expanded(
                  child: FullWidthButton(
                    text: AppStrings.semanticBackButton,
                    onPressed: _back,
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.primary,
                    textColor: AppColors.primary,
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                child: FullWidthButton(
                  text: _step == 2
                      ? AppStrings.semanticAddVaccineButton
                      : AppStrings.semanticContinueButton,
                  onPressed: _step == 2 ? _submit : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepContent() {
    switch (_step) {
      case 0:
        return [
          AppFormField(
            label: '${AppStrings.labelVaccineName} *',
            hintText: AppStrings.hintVaccineName,
            controller: _vaccineController,
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
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.validationInvalidDate;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelProductName,
            hintText: AppStrings.hintProductName,
            controller: _productController,
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
            controller: _petNameController,
          ),
        ];
      case 1:
        return [
          AppFormField(
            label: AppStrings.labelAdministeredBy,
            hintText: AppStrings.hintAdministeredBy,
            controller: _administeredByController,
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.labelAdditionalFiles,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primaryVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.uploadDocuments,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              AppStrings.uploadHint,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.grey700,
              ),
            ),
          ),
        ];
      case 2:
      default:
        return [
          AppFormField(
            label: AppStrings.labelVaccineName,
            hintText: AppStrings.hintNotProvided,
            controller: _vaccineController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelDate,
            hintText: AppStrings.hintNotProvided,
            controller: _dateController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelProductName,
            hintText: AppStrings.hintNotProvided,
            controller: _productController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelPetName,
            hintText: AppStrings.hintNotProvided,
            controller: _petNameController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelAdministeredBy,
            hintText: AppStrings.hintNotProvided,
            controller: _administeredByController,
            readOnly: true,
          ),
        ];
    }
  }
}
