import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/stepper.dart' as app_stepper;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/pet_service.dart';
import '../../../../core/services/profile_photo_service.dart';
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
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final ImagePicker _imagePicker = ImagePicker();

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
  String? _localPetPhotoPath;
  bool _isCreatingPet = false;

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

  Future<void> _submit() async {
    if (!_validateCurrentStep()) {
      return;
    }

    final birthDate = _parseDate(_dateOfBirthController.text);
    if (birthDate == null) {
      context.showSnackBar(AppStrings.addPetValidationRequired, isError: true);
      return;
    }

    setState(() {
      _isCreatingPet = true;
    });

    try {
      final createdPet = await PetService().createPet({
        'name': _nameController.text.trim(),
        'species': _species == PetSpecies.cat ? 'cat' : 'dog',
        'breed': _breedController.text.trim(),
        'gender': _gender == PetGender.female ? 'female' : 'male',
        'birthDate':
            '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
        'weight': double.tryParse(_weightController.text.trim()) ?? 0,
        'color': _colorController.text.trim(),
        'knownAllergies': _allergiesController.text.trim(),
        'defaultVet': _veterinarianController.text.trim(),
        'defaultClinic': _clinicController.text.trim(),
      });

      if (_localPetPhotoPath != null && _localPetPhotoPath!.isNotEmpty) {
        await _photoService.savePetPhotoPath(
          petId: createdPet.id,
          filePath: _localPetPhotoPath!,
        );
      }

      if (!mounted) {
        return;
      }

      context.showSnackBar(AppStrings.addPetSavedMessage);
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      context.showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showSnackBar(AppStrings.petsLoadError, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPet = false;
        });
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final extension = _extensionFromName(pickedFile.name);
      final photoPath = await _photoService.saveImageFileLocally(
        bytes: bytes,
        directoryName: 'pet_photos',
        fileNamePrefix: 'pet_draft',
        extension: extension,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _localPetPhotoPath = photoPath;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showSnackBar(AppStrings.profilePhotoPickError, isError: true);
    }
  }

  String _extensionFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'png';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (lower.endsWith('.heic')) {
      return 'heic';
    }
    return 'jpg';
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
          onPressed: _isCreatingPet ? null : _goBack,
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
                onPressed: _isCreatingPet
                    ? null
                    : (_currentStep == 2 ? _submit : _continue),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.bottomNavActive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isCreatingPet
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
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
          onPhotoTap: _pickPhotoFromGallery,
          imageFile:
              _localPetPhotoPath == null ? null : File(_localPetPhotoPath!),
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
