import 'package:flutter/material.dart';
import '../../../widgets/stepper.dart' as app_stepper;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/context_extensions.dart';
import 'add_pet_form_types.dart';
import 'steps/step_basic_info.dart';
import 'steps/step_details.dart';
import 'steps/step_medical.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _veterinarianController = TextEditingController();
  final _clinicController = TextEditingController();
  final _allergiesController = TextEditingController();

  int _currentStep = 0;
  PetSpecies? _species;
  PetGender? _gender;

  static const _stepLabels = [
    AppStrings.addPetStepBasicInfo,
    AppStrings.addPetStepDetails,
    AppStrings.addPetStepMedical,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _dateOfBirthController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _veterinarianController.dispose();
    _clinicController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final parsedDate = _parseDate(_dateOfBirthController.text);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: parsedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) {
      return;
    }

    final day = pickedDate.day.toString().padLeft(2, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final year = pickedDate.year.toString();
    _dateOfBirthController.text = '$day/$month/$year';
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
    if (parsed == null || parsed.isAfter(DateTime.now())) {
      return null;
    }

    return parsed;
  }

  void _goBack() {
    if (_currentStep == 0) {
      context.pop();
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _continue() {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _submit() {
    if (!_validateCurrentStep()) {
      return;
    }

    context.showSnackBar(AppStrings.addPetSavedMessage);
    context.pop();
  }

  bool _validateCurrentStep() {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (_currentStep == 0 && _species == null) {
      context.showSnackBar(AppStrings.addPetValidationRequired, isError: true);
      return false;
    }

    if (_currentStep == 1 && _gender == null) {
      context.showSnackBar(AppStrings.addPetValidationRequired, isError: true);
      return false;
    }

    return formValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
          tooltip: AppStrings.semanticBackButton,
        ),
        title: const Text(AppStrings.addPetTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceM,
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceXXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                app_stepper.Stepper(
                  steps: _stepLabels,
                  currentStep: _currentStep,
                  activeColor: AppColors.bottomNavActive,
                  activeTextColor: AppColors.bottomNavActive,
                  inactiveTextColor: AppColors.grey500,
                  inactiveColor: AppColors.addPetStepInactiveCircle,
                  lineColor: AppColors.grey300,
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppDimensions.pageHorizontalPadding,
          AppDimensions.spaceM,
          AppDimensions.pageHorizontalPadding,
          AppDimensions.spaceXXL + AppDimensions.spaceM,
        ),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    side: const BorderSide(color: AppColors.bottomNavActive),
                    foregroundColor: AppColors.bottomNavActive,
                  ),
                  child: const Text(AppStrings.addPetBackButton),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _currentStep == 2 ? _submit : _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.bottomNavActive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  _currentStep == 2
                      ? AppStrings.semanticAddPetButton
                      : AppStrings.semanticContinueButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return StepBasicInfo(
          nameController: _nameController,
          breedController: _breedController,
          species: _species,
          onSpeciesSelected: (species) {
            setState(() {
              _species = species;
            });
          },
          onPhotoTap: () {
            context.showSnackBar(AppStrings.addPetPhotoHint);
          },
        );
      case 1:
        return StepDetails(
          dateOfBirthController: _dateOfBirthController,
          weightController: _weightController,
          colorController: _colorController,
          gender: _gender,
          onPickDate: _pickDateOfBirth,
          onGenderSelected: (gender) {
            setState(() {
              _gender = gender;
            });
          },
        );
      case 2:
      default:
        return StepMedical(
          veterinarianController: _veterinarianController,
          clinicController: _clinicController,
          allergiesController: _allergiesController,
        );
    }
  }
}
