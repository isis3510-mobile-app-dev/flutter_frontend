import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/stepper.dart' as app_stepper;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/attachment_upload_service.dart';
import '../../../../core/services/pet_service.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../../core/services/telemetry_service.dart';
import '../../../../core/utils/context_extensions.dart';
import '../models/pet_ui_model.dart';
import 'add_pet_form_types.dart';
import 'steps/step_basic_info.dart';
import 'steps/step_details.dart';
import 'steps/step_medical.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, this.editingPet});

  final PetUiModel? editingPet;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();
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
  String? _petPhotoPath;
  bool _didRemovePhoto = false;
  bool _isCreatingPet = false;
  bool _didSubmitSuccessfully = false;

  bool get _isEditMode => widget.editingPet != null;

  static const _stepLabels = [
    AppStrings.addPetStepBasicInfo,
    AppStrings.addPetStepDetails,
    AppStrings.addPetStepMedical,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  @override
  void dispose() {
    if (!_isEditMode && !_didSubmitSuccessfully) {
      TelemetryService().cancelAddPetTimer();
    }
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

  Future<void> _loadInitialValues() async {
    final editingPet = widget.editingPet;
    if (editingPet == null) {
      return;
    }

    _nameController.text = _normalizeInitialText(editingPet.name);
    _breedController.text = _normalizeInitialText(editingPet.breed);
    _dateOfBirthController.text =
        '${editingPet.birthDate.day.toString().padLeft(2, '0')}/${editingPet.birthDate.month.toString().padLeft(2, '0')}/${editingPet.birthDate.year.toString().padLeft(4, '0')}';
    _weightController.text =
        editingPet.weight == editingPet.weight.roundToDouble()
        ? editingPet.weight.toInt().toString()
        : editingPet.weight.toStringAsFixed(1);
    _colorController.text = _normalizeInitialText(editingPet.color);
    _veterinarianController.text = _normalizeInitialText(editingPet.defaultVet);
    _clinicController.text = _normalizeInitialText(editingPet.defaultClinic);
    _allergiesController.text = _normalizeInitialText(
      editingPet.knownAllergies,
    );
    _species = _speciesFromValue(editingPet.species);
    _gender = _genderFromValue(editingPet.gender);

    final localPath = await _photoService.getPetPhotoPath(editingPet.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _petPhotoPath = localPath ?? editingPet.photoUrl?.trim();
    });
  }

  String _normalizeInitialText(String value) {
    return value == AppStrings.valueNotAvailable ? '' : value;
  }

  PetSpecies _speciesFromValue(String value) {
    return value.toLowerCase().trim() == 'cat'
        ? PetSpecies.cat
        : PetSpecies.dog;
  }

  PetGender _genderFromValue(String value) {
    return value.toLowerCase().trim() == 'female'
        ? PetGender.female
        : PetGender.male;
  }

  Map<String, dynamic> _buildPetPayload(DateTime birthDate) {
    final payload = <String, dynamic>{
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
    };

    final currentPhotoPath = _petPhotoPath?.trim();
    if (_isRemotePhotoPath(currentPhotoPath)) {
      payload['photoUrl'] = currentPhotoPath;
    } else if (_didRemovePhoto) {
      payload['photoUrl'] = '';
    }

    return payload;
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
      if (!_isEditMode) {
        TelemetryService().cancelAddPetTimer();
      }
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
    if (_isCreatingPet) {
      return;
    }

    if (!_validateCurrentStep()) {
      return;
    }

    final birthDate = _parseDate(_dateOfBirthController.text);
    if (birthDate == null) {
      context.showSnackBar(AppStrings.addPetValidationRequired, isError: true);
      return;
    }

    if (!_isEditMode) {
      TelemetryService().startAddPetTimer();
    }

    setState(() {
      _isCreatingPet = true;
    });

    try {
      final petService = PetService();
      final payload = _buildPetPayload(birthDate);
      var savedPet = _isEditMode
          ? await petService.updatePet(
              petId: widget.editingPet!.id,
              data: payload,
            )
          : await petService.createPet(payload);

      if (_petPhotoPath != null &&
          _petPhotoPath!.isNotEmpty &&
          !_isRemotePhotoPath(_petPhotoPath)) {
        final pickedFile = XFile(_petPhotoPath!);
        final uploadedPhoto = await _attachmentUploadService.uploadPetPhoto(
          bytes: await pickedFile.readAsBytes(),
          petId: savedPet.id,
          fileName: pickedFile.name,
        );

        savedPet = await petService.updatePet(
          petId: savedPet.id,
          data: {...payload, 'photoUrl': uploadedPhoto.downloadUrl},
        );

        await _photoService.clearPetPhotoPath(savedPet.id);

        if (mounted) {
          setState(() {
            _petPhotoPath = uploadedPhoto.downloadUrl;
            _didRemovePhoto = false;
          });
        }
      }

      if (!mounted) {
        return;
      }

      if (!_isEditMode) {
        _didSubmitSuccessfully = true;
      }

      context.showSnackBar(
        _isEditMode
            ? AppStrings.editPetSavedMessage
            : AppStrings.addPetSavedMessage,
      );
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (!_isEditMode) {
        TelemetryService().cancelAddPetTimer();
      }
      context.showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (!_isEditMode) {
        TelemetryService().cancelAddPetTimer();
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
        _petPhotoPath = photoPath;
        _didRemovePhoto = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showSnackBar(AppStrings.profilePhotoPickError, isError: true);
    }
  }

  Future<void> _removePhoto() async {
    final petId = widget.editingPet?.id;
    if (petId != null) {
      await _photoService.clearPetPhotoPath(petId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _petPhotoPath = null;
      _didRemovePhoto = true;
    });
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

  bool _isRemotePhotoPath(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
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
        title: Text(
          _isEditMode ? AppStrings.editPetTitle : AppStrings.addPetTitle,
        ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _currentStep == 2
                            ? (_isEditMode
                                  ? AppStrings.actionEdit
                                  : AppStrings.semanticAddPetButton)
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
          onRemovePhoto: _removePhoto,
          imagePath: _petPhotoPath,
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
