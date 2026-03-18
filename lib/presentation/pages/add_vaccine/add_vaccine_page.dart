import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/models/vaccine_model.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/utils/date_input.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_scaffold.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_basic.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_details.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_overview.dart';
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
  String? _editingVaccinationId;
  AddVaccineArgs? _pendingPrefill;

  int _step = 0;

  bool get _isEditing => widget.prefill != null;

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
      _dateController.text = formatDateForInput(prefill.dateGiven!);
    }
    if (prefill.vaccinationId != null &&
        prefill.vaccinationId!.trim().isNotEmpty) {
      _editingVaccinationId = prefill.vaccinationId!.trim();
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
          .map(_extractPetId)
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final pets = <PetModel>[];
      for (final petId in petIds) {
        try {
          final pet = await _petService.getPetById(petId);
          pets.add(pet);
        } catch (_) {
          // Skip missing/invalid pet ids to avoid crashing the flow.
        }
      }
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

  String _extractPetId(dynamic pet) {
    if (pet is String) {
      return pet;
    }
    if (pet is Map) {
      final id = pet['id'] ?? pet['petId'] ?? pet['pet_id'];
      if (id != null) {
        return id.toString();
      }
    }
    return pet?.toString() ?? '';
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
    final initialDate =
        _parseDateInput(_dateController.text.trim()) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    _dateController.text = formatDateForInput(pickedDate);
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

    final dateGiven = parseDateInput(_dateController.text.trim());
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
      final selectedPetId = _selectedPetId?.trim() ?? '';
      final selectedVaccineId =
          (_selectedVaccineId ?? _originalVaccineId)?.trim() ?? '';

      if (selectedPetId.isEmpty || selectedVaccineId.isEmpty) {
        throw const FormatException('Missing vaccine or pet selection.');
      }

      final vaccine = _vaccines.firstWhere(
        (item) => item.id == selectedVaccineId,
        orElse: () => const VaccineModel(id: '', schema: '', name: ''),
      );
      final intervalDays = vaccine.intervalDays;
      final originalDateGiven = _originalDateGiven ?? dateGiven;
      final isDateChanged = !_isSameCalendarDay(originalDateGiven, dateGiven);
      final nextDueDate = intervalDays > 0
          ? dateGiven.add(Duration(days: intervalDays))
          : null;

      final payload = <String, dynamic>{
        'vaccineId': selectedVaccineId,
        'dateGiven': _formatDateForApi(
          _isEditing ? originalDateGiven : dateGiven,
        ),
        'nextDueDate': nextDueDate == null ? null : _formatDateForApi(nextDueDate),
        'lotNumber': '',
        'status': 'completed',
        'administeredBy': _administeredByController.text.trim(),
        'clinicName': '',
        'attachedDocuments': const [],
      };

      if (_isEditing && isDateChanged) {
        payload['newDateGiven'] = _formatDateForApi(dateGiven);
      }

      if (!_isEditing) {
        await _petService.addVaccination(
          petId: selectedPetId,
          data: payload,
        );
      } else {
        await _petService.updateVaccinationByVaccineId(
          petId: selectedPetId,
          data: payload,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !_isEditing
                ? 'Vaccine saved successfully.'
                : 'Vaccine updated successfully.',
          ),
        ),
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
    final showBackButton = _step > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vaccine' : AppStrings.addVaccineTitle),
      ),
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
              if (showBackButton)
                Flexible(
                  flex: 4,
                  child: FullWidthButton(
                    text: AppStrings.semanticBackButton,
                    onPressed: _back,
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.primary,
                    textColor: AppColors.primary,
                  ),
                ),
              if (showBackButton) const SizedBox(width: 12),
              Flexible(
                flex: showBackButton ? 6 : 1,
                child: FullWidthButton(
                  text: _step == 2
                      ? (!_isEditing
                          ? AppStrings.semanticAddVaccineButton
                          : AppStrings.semanticUpdateVaccineButton)
                      : AppStrings.semanticContinueButton,
                  onPressed: _step == 2 ? _submit : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    return AddFlowScaffold(
      title: AppStrings.addVaccineTitle,
      formKey: _formKey,
      steps: const [
        AppStrings.stepBasicInfo,
        AppStrings.stepDetails,
        AppStrings.stepOverview,
      ],
      currentStep: _step,
      stepContent: _buildStepContent(),
      primaryButtonText: _step == 2
          ? (widget.prefill == null
              ? AppStrings.semanticAddVaccineButton
              : AppStrings.semanticUpdateVaccineButton)
          : AppStrings.semanticContinueButton,
      onPrimaryPressed: _step == 2 ? _submit : _continue,
      onBackPressed: _back,
      backButtonText: AppStrings.semanticBackButton,
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
            enabled: !_isLoadingVaccines && !_isEditing,
            onChanged: (value) {
          AddVaccineStepBasic(
            isLoadingVaccines: _isLoadingVaccines,
            isLoadingPets: _isLoadingPets,
            selectedVaccineName: _selectedVaccineName,
            selectedProductName: _selectedProductName,
            selectedPetName: _selectedPetName,
            vaccineNameOptions: _vaccineNameOptions,
            productOptions: _productOptions,
            petNameOptions: _petNameOptions,
            onVaccineChanged: (value) {
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
            enabled: _selectedVaccineName != null && _productOptions.isNotEmpty && !_isEditing,
            onChanged: (value) {
            onProductChanged: (value) {
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
            enabled: !_isLoadingPets && _petNameOptions.isNotEmpty && !_isEditing,
            onChanged: (value) {
            onPetChanged: (value) {
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
            onPickDate: _pickDate,
            dateController: _dateController,
          ),
        ];
      case 1:
        return [
          AddVaccineStepDetails(
            administeredByController: _administeredByController,
          ),
        ];
      case 2:
      default:
        return [
          AddVaccineStepOverview(
            vaccineController: _vaccineController,
            dateController: _dateController,
            productController: _productController,
            petNameController: _petNameController,
            administeredByController: _administeredByController,
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
  // Format as ISO8601 with Z suffix: 2026-03-18T00:00:00Z
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00Z';
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

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
          initialValue: value,
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
