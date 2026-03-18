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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        'dateGiven': formatDateForApi(dateGiven),
        'nextDueDate': nextDueDate == null ? null : formatDateForApi(nextDueDate),
        'lotNumber': '',
        'status': 'completed',
        'administeredBy': _administeredByController.text.trim(),
        'clinicName': '',
        'attachedDocuments': const [],
      };

      if (widget.prefill == null) {
        await _petService.addVaccination(
          petId: _selectedPetId!,
          data: payload,
        );
      } else {
        if (_editingVaccinationId == null ||
            _editingVaccinationId!.trim().isEmpty) {
          throw Exception('Missing vaccination id for update.');
        }
        await _petService.updateVaccination(
          petId: _selectedPetId!,
          vaccinationId: _editingVaccinationId!,
          data: payload,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.prefill == null
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

