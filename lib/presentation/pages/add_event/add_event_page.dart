import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/utils/date_input.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_scaffold.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_basic.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_details.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_overview.dart';
import 'add_event_args.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key, this.prefill});

  final AddEventArgs? prefill;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  final _eventTypeController = TextEditingController();
  final _priceController = TextEditingController();
  final _providerController = TextEditingController();
  final _clinicController = TextEditingController();
  final _followUpDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _petNameController = TextEditingController();

  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final EventService _eventService = EventService();
  final List<PetModel> _pets = [];

  bool _isLoadingPets = false;
  bool _isSubmitting = false;
  String? _selectedPetName;
  String? _selectedPetId;
  String? _ownerId;
  String? _editingEventId;
  AddEventArgs? _pendingPrefill;

  int _step = 0;

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill);
    _loadPets();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    _eventTypeController.dispose();
    _priceController.dispose();
    _providerController.dispose();
    _clinicController.dispose();
    _followUpDateController.dispose();
    _descriptionController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  void _applyPrefill(AddEventArgs? prefill) {
    if (prefill == null) {
      return;
    }

    _pendingPrefill = prefill;

    if (prefill.title != null && prefill.title!.trim().isNotEmpty) {
      _eventController.text = prefill.title!.trim();
    }

    if (prefill.description != null && prefill.description!.trim().isNotEmpty) {
      _descriptionController.text = prefill.description!.trim();
    }

    if (prefill.petName != null && prefill.petName!.trim().isNotEmpty) {
      _petNameController.text = prefill.petName!.trim();
      _selectedPetName = prefill.petName!.trim();
    }

    if (prefill.date != null) {
      _dateController.text = formatDateForInput(prefill.date!);
      final hour = prefill.date!.hour.toString().padLeft(2, '0');
      final minute = prefill.date!.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$minute';
    }

    if (prefill.eventId != null && prefill.eventId!.trim().isNotEmpty) {
      _editingEventId = prefill.eventId!.trim();
    }

    if (prefill.eventType != null && prefill.eventType!.trim().isNotEmpty) {
      _eventTypeController.text = prefill.eventType!.trim();
    }

    if (prefill.price != null) {
      _priceController.text = prefill.price!.toString();
    }

    if (prefill.provider != null && prefill.provider!.trim().isNotEmpty) {
      _providerController.text = prefill.provider!.trim();
    }

    if (prefill.clinic != null && prefill.clinic!.trim().isNotEmpty) {
      _clinicController.text = prefill.clinic!.trim();
    }

    if (prefill.followUpDate != null) {
      _followUpDateController.text = formatDateForInput(prefill.followUpDate!);
    }

    if (_pets.isNotEmpty) {
      _applyPetSelectionFromPrefill(prefill);
    }
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);

    try {
      final profile = await _userService.getCurrentUser();
      _ownerId = profile.id.trim().isEmpty ? null : profile.id.trim();
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
          // Skip missing/invalid pet ids to keep the flow working.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pets
          ..clear()
          ..addAll(pets);
      });

      if (_pendingPrefill != null) {
        _applyPetSelectionFromPrefill(_pendingPrefill!);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

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

  void _applyPetSelectionFromPrefill(AddEventArgs prefill) {
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
      final selectedName = prefill.petName!.trim();
      final match = _pets.firstWhere(
        (pet) => pet.name == selectedName,
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

  String? _normalizeOwnerIdCandidate(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final directObjectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');
    if (directObjectIdPattern.hasMatch(trimmed)) {
      return trimmed;
    }

    final embeddedObjectId = RegExp(r'([a-fA-F0-9]{24})').firstMatch(trimmed);
    if (embeddedObjectId != null) {
      return embeddedObjectId.group(1);
    }

    if (trimmed.contains('{') || trimmed.contains('}')) {
      return null;
    }

    return trimmed;
  }

  String? _extractOwnerIdFromOwners(List<String> owners) {
    for (final owner in owners) {
      final normalized = _normalizeOwnerIdCandidate(owner);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  String? _resolveOwnerIdFromSelectedPet() {
    final selectedPetId = _selectedPetId?.trim();
    if (selectedPetId == null || selectedPetId.isEmpty) {
      return null;
    }

    for (final pet in _pets) {
      if (pet.id == selectedPetId) {
        return _extractOwnerIdFromOwners(pet.owners);
      }
    }

    return null;
  }

  String? _resolveOwnerIdLocally() {
    final ownerFromProfile = _normalizeOwnerIdCandidate(_ownerId);
    if (ownerFromProfile != null && ownerFromProfile.isNotEmpty) {
      return ownerFromProfile;
    }

    final ownerFromSelectedPet = _resolveOwnerIdFromSelectedPet();
    if (ownerFromSelectedPet != null && ownerFromSelectedPet.isNotEmpty) {
      return ownerFromSelectedPet;
    }

    for (final pet in _pets) {
      final ownerFromPet = _extractOwnerIdFromOwners(pet.owners);
      if (ownerFromPet != null && ownerFromPet.isNotEmpty) {
        return ownerFromPet;
      }
    }

    return null;
  }

  Future<String?> _resolveOwnerIdForSubmit() async {
    final localOwnerId = _resolveOwnerIdLocally();
    if (localOwnerId != null && localOwnerId.isNotEmpty) {
      return localOwnerId;
    }

    try {
      final profile = await _userService.getCurrentUser();
      final refreshedOwnerId = _normalizeOwnerIdCandidate(profile.id);
      if (refreshedOwnerId != null && refreshedOwnerId.isNotEmpty) {
        _ownerId = refreshedOwnerId;
        return refreshedOwnerId;
      }
    } catch (_) {
      // Keep the existing UX fallback below.
    }

    return _resolveOwnerIdLocally();
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

  Future<void> _pickFollowUpDate() async {
    final existingFollowUp = parseDateInput(_followUpDateController.text.trim());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: existingFollowUp ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    _followUpDateController.text = formatDateForInput(pickedDate);
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

  Future<void> _pickTime() async {
    final existingTime = _parseTimeInput(_timeController.text.trim());
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: existingTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    _timeController.text = '$hour:$minute';
  }

  void _back() {
    setState(() {
      if (_step > 0) {
        _step--;
      }
    });
  }

  TimeOfDay? _parseTimeInput(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _submit() async {
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

    final resolvedOwnerId = await _resolveOwnerIdForSubmit();
    if (!mounted) {
      return;
    }

    if (resolvedOwnerId == null || resolvedOwnerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve owner id. Please try again.')),
      );
      return;
    }

    final selectedDate = parseDateInput(_dateController.text.trim());
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid date.')),
      );
      return;
    }

    final selectedTime = _parseTimeInput(_timeController.text.trim());
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid time (HH:mm).')),
      );
      return;
    }

    final eventDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await _submitToApi(eventDateTime, resolvedOwnerId);
  }

  Future<void> _submitToApi(DateTime eventDateTime, String ownerId) async {
    setState(() => _isSubmitting = true);

    try {
      final title = _eventController.text.trim();
      final eventType = _eventTypeController.text.trim().isNotEmpty
          ? _eventTypeController.text.trim()
          : _resolveEventType(title);
      final rawPrice = _priceController.text.trim().replaceAll(',', '.');
      final parsedPrice = rawPrice.isEmpty ? null : double.tryParse(rawPrice);

      final parsedFollowUpDate = parseDateInput(
        _followUpDateController.text.trim(),
      );
      final followUpDateTime = parsedFollowUpDate == null
          ? null
          : DateTime(
              parsedFollowUpDate.year,
              parsedFollowUpDate.month,
              parsedFollowUpDate.day,
              eventDateTime.hour,
              eventDateTime.minute,
            );

      final eventDateIso = eventDateTime.toUtc().toIso8601String();
      final followUpDateIso = followUpDateTime?.toUtc().toIso8601String();

      final payload = <String, dynamic>{
        'petId': _selectedPetId,
        'title': title,
        'eventType': eventType,
        'date': eventDateIso,
        'price': parsedPrice,
        'provider': _providerController.text.trim(),
        'clinic': _clinicController.text.trim(),
        'description': _descriptionController.text.trim(),
        'followUpDate': followUpDateIso,
      };

      if (_editingEventId == null || _editingEventId!.trim().isEmpty) {
        await _eventService.createEvent({
          ...payload,
          'ownerId': ownerId,
          'schema': 1,
          'attachedDocuments': const <Map<String, dynamic>>[],
        });
      } else {
        await _eventService.updateEvent(
          eventId: _editingEventId!,
          data: payload,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingEventId == null || _editingEventId!.trim().isEmpty
                ? 'Event saved successfully.'
                : 'Event updated successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _resolveEventType(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('vaccin') || normalized.contains('vacun')) {
      return 'vaccination';
    }
    if (normalized.contains('groom') || normalized.contains('bano')) {
      return 'grooming';
    }
    if (normalized.contains('dental')) {
      return 'dental';
    }
    if (normalized.contains('emergen')) {
      return 'emergency';
    }
    if (normalized.contains('vet') || normalized.contains('check')) {
      return 'vet_visit';
    }

    return 'general';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingEventId != null && _editingEventId!.trim().isNotEmpty;

    return AddFlowScaffold(
      title: AppStrings.addEventTitle,
      formKey: _formKey,
      steps: const [
        AppStrings.stepBasicInfo,
        AppStrings.stepDetails,
        AppStrings.stepOverview,
      ],
      currentStep: _step,
      stepContent: _buildStepContent(),
      primaryButtonText: _step == 2
          ? (isEditing
            ? AppStrings.actionEdit
            : AppStrings.semanticAddEventButton)
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
          AddEventStepBasic(
            isLoadingPets: _isLoadingPets,
            selectedPetName: _selectedPetName,
            petNameOptions: _petNameOptions,
            onPetChanged: (value) {
              setState(() {
                _selectedPetName = value;
                _petNameController.text = value ?? '';

                if (value == null || value.trim().isEmpty) {
                  _selectedPetId = null;
                  return;
                }

                final selectedPet = _pets.firstWhere(
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

                _selectedPetId = selectedPet.id.isEmpty ? null : selectedPet.id;
              });
            },
            eventController: _eventController,
            dateController: _dateController,
            timeController: _timeController,
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
        ];
      case 1:
        return [
          AddEventStepDetails(
            eventTypeController: _eventTypeController,
            priceController: _priceController,
            providerController: _providerController,
            clinicController: _clinicController,
            followUpDateController: _followUpDateController,
            onPickFollowUpDate: _pickFollowUpDate,
            descriptionController: _descriptionController,
          ),
        ];
      case 2:
      default:
        return [
          AddEventStepOverview(
            eventController: _eventController,
            dateController: _dateController,
            timeController: _timeController,
            petNameController: _petNameController,
            eventTypeController: _eventTypeController,
            priceController: _priceController,
            providerController: _providerController,
            clinicController: _clinicController,
            followUpDateController: _followUpDateController,
            descriptionController: _descriptionController,
          ),
        ];
    }
  }
}
