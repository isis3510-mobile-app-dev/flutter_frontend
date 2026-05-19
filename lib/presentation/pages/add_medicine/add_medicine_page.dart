import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/medicine_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/utils/date_input.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_scaffold.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/app_dropdown_field.dart';
import 'package:flutter_frontend/shared/widgets/form_field.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  final MedicineService _medicineService = MedicineService();
  final PetService _petService = PetService();

  final List<String> _administrationOptions = ['oral', 'topical', 'injectable'];
  final List<String> _dosageUnitOptions = ['g', 'mg', 'ml', 'tablet', 'drops'];

  List<PetModel> _pets = [];
  String? _selectedPetId;
  String? _selectedAdministration;
  String? _selectedDosageUnit;
  int _step = 0;
  bool _isLoadingPets = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);
    try {
      final pets = await _petService.getPets();
      if (!mounted) return;
      setState(() => _pets = pets);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = parseDateInput(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = formatDateForInput(picked);
  }

  bool _isValidDate(String value) {
    return parseDateInput(value) != null;
  }

  Future<void> _submit() async {
    AppFormSanitizers.trimControllers([
      _nameController,
      _dosageController,
      _frequencyController,
      _startDateController,
      _endDateController,
    ]);

    if (!_formKey.currentState!.validate()) return;
    if ((_selectedPetId?.trim() ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.validationSelectPet)));
      return;
    }

    final payload = {
      'petId': _selectedPetId,
      'medicineName': _nameController.text.trim(),
      'administrationRoute': _selectedAdministration ?? _administrationOptions.first,
      'dosageValue': double.tryParse(_dosageController.text.trim()) ?? 0.0,
      'dosageUnit': _selectedDosageUnit ?? 'mg',
      'frequency': int.tryParse(_frequencyController.text.trim()) ?? 24,
      'startDate': _startDateController.text.trim().isEmpty ? null : formatDateForApi(parseDateInput(_startDateController.text) ?? DateTime.now()),
      'endDate': _endDateController.text.trim().isEmpty ? null : formatDateForApi(parseDateInput(_endDateController.text) ?? DateTime.now()),
      'reminderEnabled': false,
    }..removeWhere((key, value) => value == null);

    setState(() => _isSubmitting = true);
    try {
      await _medicineService.createMedicine(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 1) {
      setState(() => _step += 1);
      return;
    }
    _submit();
  }

  void _previousStep() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final petOptions = _pets.map((p) => p.name.trim()).toList(growable: false);
    final selectedPetName = _selectedPetId == null
      ? null
      : _pets
        .where((p) => p.id == _selectedPetId)
        .map((p) => p.name.trim())
        .cast<String?>()
        .firstWhere((name) => name != null && name.isNotEmpty, orElse: () => null);

    final basic = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdownField(
          label: '${AppStrings.labelPetName} *',
          hintText: _isLoadingPets ? 'Loading pets...' : 'Select pet',
          value: selectedPetName,
          items: petOptions,
          enabled: !_isLoadingPets && petOptions.isNotEmpty,
          onChanged: (name) {
            final normalizedName = (name ?? '').trim();
            final match = _pets.firstWhere(
              (p) => p.name.trim() == normalizedName,
              orElse: () => PetModel(id: '', schema: 1, owners: [], name: '', species: '', breed: '', gender: '', birthDate: null, weight: null, color: '', photoUrl: null, status: '', isNfcSynced: false, knownAllergies: '', defaultVet: '', defaultClinic: '', vaccinations: []),
            );
            if (match.id.isNotEmpty) setState(() => _selectedPetId = match.id);
          },
          validator: (value) {
            if ((value == null || value.trim().isEmpty) || (_selectedPetId == null || _selectedPetId!.trim().isEmpty)) {
              return AppStrings.validationSelectPet;
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: '${AppStrings.labelMedicineName} *',
          hintText: AppStrings.hintMedicineName,
          controller: _nameController,
          inputFormatters: [LengthLimitingTextInputFormatter(AppFormConstraints.eventTitleMaxLength)],
          validator: AppFormValidators.required('Enter medicine name'),
        ),
        const SizedBox(height: 18),
        AppDropdownField(
          label: 'Administration route *',
          hintText: 'Select route',
          items: _administrationOptions.map((e) => e[0].toUpperCase() + e.substring(1)).toList(),
          value: _selectedAdministration == null ? null : (_selectedAdministration![0].toUpperCase() + _selectedAdministration!.substring(1)),
          onChanged: (v) {
            if (v == null) return;
            final normalized = v.toLowerCase();
            setState(() => _selectedAdministration = normalized);
          },
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Select administration route' : null,
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: AppFormField(
              label: 'Dosage',
              hintText: 'Value',
              controller: _dosageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: AppInputFormatters.decimal(maxWholeDigits: 6, decimalDigits: 2),
              validator: AppFormValidators.optionalDecimal(invalidMessage: 'Invalid number'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: AppDropdownField(
              label: 'Unit',
              hintText: 'Unit',
              items: _dosageUnitOptions.map((u) => u).toList(),
              value: _selectedDosageUnit,
              onChanged: (v) => setState(() => _selectedDosageUnit = v),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        AppFormField(
          label: 'Frequency (hours)',
          hintText: 'e.g. 8',
          controller: _frequencyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          validator: (v) {
            final trimmed = v?.trim() ?? '';
            if (trimmed.isEmpty) return null;
            final parsed = int.tryParse(trimmed);
            if (parsed == null) return AppStrings.validationInvalidNumber;
            if (parsed <= 0 || parsed > 99) return 'Enter a value between 1 and 99.';
            return null;
          },
        ),
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormField(
          label: '${AppStrings.labelDate} start',
          hintText: AppStrings.hintDate,
          icon: Icons.calendar_today_outlined,
          controller: _startDateController,
          readOnly: true,
          onTap: () => _pickDate(_startDateController),
          validator: (v) {
            final trimmed = v?.trim() ?? '';
            if (trimmed.isEmpty) return null;
            if (!_isValidDate(trimmed)) return AppStrings.validationInvalidDate;
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppFormField(
          label: '${AppStrings.labelDate} end',
          hintText: AppStrings.hintDate,
          icon: Icons.calendar_today_outlined,
          controller: _endDateController,
          readOnly: true,
          onTap: () => _pickDate(_endDateController),
          validator: (v) {
            final trimmed = v?.trim() ?? '';
            if (trimmed.isEmpty) return null;
            if (!_isValidDate(trimmed)) return AppStrings.validationInvalidDate;
            final start = parseDateInput(_startDateController.text);
            final end = parseDateInput(trimmed);
            if (start != null && end != null && end.isBefore(start)) {
              return AppStrings.validationEndBeforeStart;
            }
            return null;
          },
        ),
      ],
    );

    return AddFlowScaffold(
      title: 'Add Medicine',
      formKey: _formKey,
      steps: const ['Basic', 'Details'],
      currentStep: _step,
      stepContent: [basic, details],
      primaryButtonText: _step == 0 ? 'Next' : 'Save',
      onPrimaryPressed: _nextStep,
      onBackPressed: _previousStep,
    );
  }
}
