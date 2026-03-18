import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/models/vaccine_model.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/presentation/widgets/stepper.dart' as app_stepper;
import 'package:flutter_frontend/shared/widgets/form_field.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

import 'add_vaccine_args.dart';

class AddVaccinePage extends StatefulWidget {
  const AddVaccinePage({super.key, this.prefill});

  final AddVaccineArgs? prefill;

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

  final VaccineService _vaccineService = VaccineService();
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final List<VaccineModel> _vaccines = [];
  final List<PetModel> _pets = [];

  bool _isLoadingVaccines = false;
  bool _isLoadingPets = false;
  bool _isSubmitting = false;
  String? _selectedVaccineName;
  String? _selectedProductName;
  String? _selectedVaccineId;
  String? _selectedPetName;
  String? _selectedPetId;
  AddVaccineArgs? _pendingPrefill;

  int _step = 0;

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill);
    _loadVaccines();
    _loadPets();
  }

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

  void _applyPrefill(AddVaccineArgs? prefill) {
    if (prefill == null) {
      return;
    }

    _pendingPrefill = prefill;

    if (prefill.vaccineName != null && prefill.vaccineName!.trim().isNotEmpty) {
      _vaccineController.text = prefill.vaccineName!.trim();
      _selectedVaccineName = prefill.vaccineName!.trim();
    }
    if (prefill.petName != null && prefill.petName!.trim().isNotEmpty) {
      _petNameController.text = prefill.petName!.trim();
      _selectedPetName = prefill.petName!.trim();
    }
    if (prefill.administeredBy != null &&
        prefill.administeredBy!.trim().isNotEmpty) {
      _administeredByController.text = prefill.administeredBy!.trim();
    }
    if (prefill.dateGiven != null) {
      _dateController.text = _formatDateForInput(prefill.dateGiven!);
    }

    if (_vaccines.isNotEmpty) {
      _applyVaccineSelectionFromPrefill(prefill);
    }
    if (_pets.isNotEmpty) {
      _applyPetSelectionFromPrefill(prefill);
    }
  }

  Future<void> _loadVaccines() async {
    setState(() => _isLoadingVaccines = true);
    try {
      final vaccines = await _vaccineService.getVaccines();
      if (!mounted) return;
      setState(() {
        _vaccines
          ..clear()
          ..addAll(vaccines);
      });
      if (_pendingPrefill != null) {
        _applyVaccineSelectionFromPrefill(_pendingPrefill!);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingVaccines = false);
      }
    }
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);
    try {
      final profile = await _userService.getCurrentUser();
      final petIds = profile.pets
          .map((pet) {
            if (pet is String) return pet;
            if (pet is Map && pet['id'] != null) return pet['id'].toString();
            return pet.toString();
          })
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final pets = await Future.wait(petIds.map(_petService.getPetById));
      if (!mounted) return;
      setState(() {
        _pets
          ..clear()
          ..addAll(pets);
      });

      if (_pendingPrefill != null) {
        _applyPetSelectionFromPrefill(_pendingPrefill!);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPets = false);
      }
    }
  }

  void _applyPetSelectionFromPrefill(AddVaccineArgs prefill) {
    if (_pets.isEmpty) {
      return;
    }

    if (prefill.petId != null && prefill.petId!.trim().isNotEmpty) {
      final match = _pets.firstWhere(
        (pet) => pet.id == prefill.petId,
        orElse: () => const PetModel(
          id: '',
          schema: 1,
          owners: [],
          name: '',
          species: '',
          breed: '',
          gender: '',
          birthDate: null,
          weight: null,
          color: '',
          photoUrl: null,
          status: '',
          isNfcSynced: false,
          knownAllergies: '',
          defaultVet: '',
          defaultClinic: '',
          vaccinations: [],
        ),
      );

      if (match.id.isNotEmpty) {
        _setSelectedPet(match);
        return;
      }
    }

    if (prefill.petName != null && prefill.petName!.trim().isNotEmpty) {
      final name = prefill.petName!.trim();
      final match = _pets.firstWhere(
        (pet) => pet.name == name,
        orElse: () => const PetModel(
          id: '',
          schema: 1,
          owners: [],
          name: '',
          species: '',
          breed: '',
          gender: '',
          birthDate: null,
          weight: null,
          color: '',
          photoUrl: null,
          status: '',
          isNfcSynced: false,
          knownAllergies: '',
          defaultVet: '',
          defaultClinic: '',
          vaccinations: [],
        ),
      );

      if (match.id.isNotEmpty) {
        _setSelectedPet(match);
      }
    }
  }

  void _setSelectedPet(PetModel pet) {
    setState(() {
      _selectedPetId = pet.id;
      _selectedPetName = pet.name;
      _petNameController.text = pet.name;
    });
  }

  void _applyVaccineSelectionFromPrefill(AddVaccineArgs prefill) {
    VaccineModel? matched;

    if (prefill.vaccineId != null && prefill.vaccineId!.trim().isNotEmpty) {
      matched = _vaccines.firstWhere(
        (vaccine) => vaccine.id == prefill.vaccineId,
        orElse: () => const VaccineModel(
          id: '',
          schema: '',
          name: '',
        ),
      );
      if (matched.id.isNotEmpty) {
        _setSelectedVaccine(matched);
        return;
      }
    }

    if (prefill.vaccineName != null && prefill.vaccineName!.trim().isNotEmpty) {
      final name = prefill.vaccineName!.trim();

      final firstMatch = _vaccines.firstWhere(
        (vaccine) => vaccine.name == name,
        orElse: () => const VaccineModel(
          id: '',
          schema: '',
          name: '',
        ),
      );
      if (firstMatch.id.isNotEmpty) {
        _setSelectedVaccine(firstMatch, keepProduct: true);
      }
    }
  }

  void _setSelectedVaccine(VaccineModel vaccine, {bool keepProduct = false}) {
    setState(() {
      _selectedVaccineId = vaccine.id;
      _selectedVaccineName = vaccine.name;
      _vaccineController.text = vaccine.name;

      if (!keepProduct) {
        _selectedProductName = vaccine.productName.trim().isEmpty
            ? null
            : vaccine.productName;
        _productController.text = _selectedProductName ?? '';
      } else if (_selectedProductName != null &&
          _selectedProductName!.trim().isNotEmpty) {
        _productController.text = _selectedProductName!.trim();
      }
    });
  }

  List<String> get _vaccineNameOptions {
    final names = _vaccines
        .map((vaccine) => vaccine.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  List<String> get _productOptions {
    if (_selectedVaccineName == null || _selectedVaccineName!.trim().isEmpty) {
      return const [];
    }
    final products = _vaccines
        .where((vaccine) => vaccine.name == _selectedVaccineName)
        .map((vaccine) => vaccine.productName.trim())
        .where((product) => product.isNotEmpty)
        .toSet()
        .toList();
    products.sort();
    return products;
  }

  List<String> get _petNameOptions {
    final names = _pets
        .map((pet) => pet.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    names.sort();
    return names;
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
    if (_isSubmitting) {
      return;
    }
    if (widget.prefill != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing is not available yet.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedPetId == null || _selectedPetId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a pet to continue.')),
      );
      return;
    }

    if (_selectedVaccineId == null || _selectedVaccineId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a valid vaccine product.')),
      );
      return;
    }

    final dateGiven = _parseDateInput(_dateController.text.trim());
    if (dateGiven == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid date.')),
      );
      return;
    }

    _submitToApi(dateGiven);
  }

  Future<void> _submitToApi(DateTime dateGiven) async {
    setState(() => _isSubmitting = true);

    try {
      final vaccine = _vaccines.firstWhere(
        (item) => item.id == _selectedVaccineId,
        orElse: () => const VaccineModel(id: '', schema: '', name: ''),
      );
      final intervalDays = vaccine.intervalDays;
      final nextDueDate = intervalDays > 0
          ? dateGiven.add(Duration(days: intervalDays))
          : null;

      final payload = <String, dynamic>{
        'vaccineId': _selectedVaccineId,
        'dateGiven': _formatDateForApi(dateGiven),
        'nextDueDate': nextDueDate == null ? null : _formatDateForApi(nextDueDate),
        'lotNumber': '',
        'status': 'completed',
        'administeredBy': _administeredByController.text.trim(),
        'clinicName': '',
        'attachedDocuments': const [],
      };

      await _petService.addVaccination(
        petId: _selectedPetId!,
        data: payload,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccine saved successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
          _AppDropdownField(
            label: '${AppStrings.labelVaccineName} *',
            hintText: _isLoadingVaccines
                ? 'Loading vaccines...'
                : AppStrings.hintVaccineName,
            value: _selectedVaccineName,
            items: _vaccineNameOptions,
            enabled: !_isLoadingVaccines,
            onChanged: (value) {
              setState(() {
                _selectedVaccineName = value;
                _selectedProductName = null;
                _selectedVaccineId = null;
                _vaccineController.text = value ?? '';
                _productController.text = '';
              });
            },
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
          _AppDropdownField(
            label: AppStrings.labelProductName,
            hintText: _selectedVaccineName == null
                ? 'Select a vaccine first'
                : _productOptions.isEmpty
                    ? 'No products available'
                    : AppStrings.hintProductName,
            value: _selectedProductName,
            items: _productOptions,
            enabled: _selectedVaccineName != null && _productOptions.isNotEmpty,
            onChanged: (value) {
              setState(() {
                _selectedProductName = value;
                _productController.text = value ?? '';
                if (_selectedVaccineName != null && value != null) {
                  final match = _vaccines.firstWhere(
                    (vaccine) =>
                        vaccine.name == _selectedVaccineName &&
                        vaccine.productName == value,
                    orElse: () => const VaccineModel(
                      id: '',
                      schema: '',
                      name: '',
                    ),
                  );
                  _selectedVaccineId = match.id.isEmpty ? null : match.id;
                }
              });
            },
            validator: (value) {
              if (_productOptions.isEmpty) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return AppStrings.validationRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _AppDropdownField(
            label: AppStrings.labelPetName,
            hintText: _isLoadingPets
                ? 'Loading pets...'
                : AppStrings.hintPetName,
            value: _selectedPetName,
            items: _petNameOptions,
            enabled: !_isLoadingPets && _petNameOptions.isNotEmpty,
            onChanged: (value) {
              setState(() {
                _selectedPetName = value;
                _petNameController.text = value ?? '';
                if (value == null) {
                  _selectedPetId = null;
                } else {
                  final match = _pets.firstWhere(
                    (pet) => pet.name == value,
                    orElse: () => const PetModel(
                      id: '',
                      schema: 1,
                      owners: [],
                      name: '',
                      species: '',
                      breed: '',
                      gender: '',
                      birthDate: null,
                      weight: null,
                      color: '',
                      photoUrl: null,
                      status: '',
                      isNfcSynced: false,
                      knownAllergies: '',
                      defaultVet: '',
                      defaultClinic: '',
                      vaccinations: [],
                    ),
                  );
                  _selectedPetId = match.id.isEmpty ? null : match.id;
                }
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.validationRequired;
              }
              return null;
            },
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

String _formatDateForInput(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String _formatDateForApi(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime? _parseDateInput(String value) {
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
  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

class _AppDropdownField extends StatelessWidget {
  const _AppDropdownField({
    required this.label,
    required this.hintText,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          icon: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.arrow_drop_down),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(growable: false),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey500),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: _dropdownBorder,
            focusedBorder: _dropdownBorder,
            disabledBorder: _dropdownBorder,
          ),
        ),
      ],
    );
  }
}

const OutlineInputBorder _dropdownBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(
    color: AppColors.grey500,
    width: 1.5,
  ),
);
