import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/services/attachment_upload_service.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/telemetry_service.dart';
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
  final TelemetryService _telemetryService = TelemetryService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();
  final List<PetModel> _pets = [];
  final List<EditableAttachmentModel> _attachedDocuments = [];

  bool _isLoadingPets = false;
  bool _isSubmitting = false;
  bool _isUploadingAttachments = false;
  bool _isLoadingExistingAttachments = false;
  bool _didTouchAttachments = false;
  bool _didHydrateExistingAttachments = false;
  String? _selectedPetName;
  String? _selectedPetId;
  String? _ownerId;
  String? _editingEventId;
  AddEventArgs? _pendingPrefill;

  int _step = 0;
  int _addEventClickCount = 1;

  @override
  void initState() {
    super.initState();
    _eventController.addListener(_syncEventTypeFromTitle);
    _applyPrefill(widget.prefill);
    _loadPets();
    _loadEditingEventIfNeeded();
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

    if (_editingEventId != null && _editingEventId!.trim().isNotEmpty) {
      _addEventClickCount = 0;
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

    _attachedDocuments
      ..clear()
      ..addAll(
        (prefill.attachedDocuments ?? const <EventDocumentModel>[]).map(
          (document) => EditableAttachmentModel(
            fileName: document.fileName,
            fileUri: document.fileUri,
            documentId: document.documentId,
          ),
        ),
      );

    if (_pets.isNotEmpty) {
      _applyPetSelectionFromPrefill(prefill);
    }

    _syncEventTypeFromTitle();
  }

  void _syncEventTypeFromTitle() {
    final title = _eventController.text.trim();
    _eventTypeController.text = title.isEmpty ? '' : _resolveEventType(title);
  }

  Future<void> _loadEditingEventIfNeeded({bool force = false}) async {
    final prefill = widget.prefill;
    if (prefill == null) {
      return;
    }

    final eventId = prefill.eventId?.trim() ?? '';
    if (eventId.isEmpty) {
      return;
    }

    if (!force && (_didTouchAttachments || _didHydrateExistingAttachments)) {
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoadingExistingAttachments = true;
        });
      }

      final event = await _eventService.getEventById(eventId);
      if (!mounted) {
        return;
      }

      setState(() {
        if (_eventController.text.trim().isEmpty) {
          _eventController.text = event.title.trim();
        }
        if (_eventTypeController.text.trim().isEmpty) {
          _eventTypeController.text = event.eventType.trim();
        }
        if (_descriptionController.text.trim().isEmpty) {
          _descriptionController.text = event.description.trim();
        }
        if (_providerController.text.trim().isEmpty) {
          _providerController.text = event.provider.trim();
        }
        if (_clinicController.text.trim().isEmpty) {
          _clinicController.text = event.clinic.trim();
        }
        if (_priceController.text.trim().isEmpty && event.price != null) {
          _priceController.text = event.price!.toString();
        }
        if (_dateController.text.trim().isEmpty && event.date.year > 1) {
          _dateController.text = formatDateForInput(event.date);
          final hour = event.date.hour.toString().padLeft(2, '0');
          final minute = event.date.minute.toString().padLeft(2, '0');
          _timeController.text = '$hour:$minute';
        }
        if (_followUpDateController.text.trim().isEmpty &&
            event.followUpDate != null) {
          _followUpDateController.text = formatDateForInput(
            event.followUpDate!,
          );
        }

        _attachedDocuments
          ..clear()
          ..addAll(
            event.attachedDocuments.map(
              (document) => EditableAttachmentModel(
                fileName: document.fileName,
                fileUri: document.fileUri,
                documentId: document.documentId,
              ),
            ),
          );
        _didHydrateExistingAttachments = true;
      });
    } catch (_) {
      // Keep the form usable even if hydration fails.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingAttachments = false;
        });
      }
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

      final petResults = await Future.wait(
        petIds.map((petId) async {
          try {
            return await _petService.getPetById(petId);
          } catch (_) {
            // Skip missing/invalid pet ids to keep the flow working.
            return null;
          }
        }),
      );
      final pets = petResults.whereType<PetModel>().toList(growable: false);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
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
    final selectedName = _selectedPetName?.trim() ?? '';
    if (selectedName.isNotEmpty && !names.contains(selectedName)) {
      names.add(selectedName);
    }
    names.sort();
    return names;
  }

  Widget _pickerThemeBuilder(BuildContext context, Widget? child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.secondaryDark,
            onSurface: AppColors.onSurfaceDark,
            onPrimary: AppColors.onPrimary,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            surface: AppColors.secondary,
            onSurface: AppColors.onSurface,
            onPrimary: AppColors.onPrimary,
          );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme,
        dialogTheme: DialogThemeData(
          backgroundColor: isDark
              ? AppColors.secondaryDark
              : AppColors.secondary,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _pickerThemeBuilder,
    );

    if (pickedDate == null) {
      return;
    }

    _dateController.text = formatDateForInput(pickedDate);
  }

  Future<void> _pickFollowUpDate() async {
    final existingFollowUp = parseDateInput(
      _followUpDateController.text.trim(),
    );
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: existingFollowUp ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _pickerThemeBuilder,
    );

    if (pickedDate == null) {
      return;
    }

    _followUpDateController.text = formatDateForInput(pickedDate);
  }

  Future<void> _continue() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_step == 0 &&
        _editingEventId != null &&
        _editingEventId!.trim().isNotEmpty &&
        !_didTouchAttachments &&
        !_didHydrateExistingAttachments) {
      await _loadEditingEventIfNeeded(force: true);
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
      builder: _pickerThemeBuilder,
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
        const SnackBar(
          content: Text('Could not resolve owner id. Please try again.'),
        ),
      );
      return;
    }

    final selectedDate = parseDateInput(_dateController.text.trim());
    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid date.')));
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
      if (_editingEventId != null &&
          _editingEventId!.trim().isNotEmpty &&
          !_didTouchAttachments &&
          !_didHydrateExistingAttachments) {
        await _loadEditingEventIfNeeded(force: true);
      }

      if (_editingEventId != null &&
          _editingEventId!.trim().isNotEmpty &&
          !_didTouchAttachments &&
          !_didHydrateExistingAttachments) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not load the existing documents for this event yet. Please try again in a moment.',
            ),
          ),
        );
        return;
      }

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
        'attachedDocuments': _attachedDocuments
            .map((attachment) => attachment.toPayload())
            .toList(growable: false),
      };

      if (_editingEventId == null || _editingEventId!.trim().isEmpty) {
        await _eventService.createEvent({
          ...payload,
          'ownerId': ownerId,
          'schema': 1,
        });
        unawaited(
          _telemetryService.logAddEventClick(nClicks: _addEventClickCount),
        );
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _registerFormTap() {
    _addEventClickCount += 1;
  }

  Future<void> _pickAndUploadAttachment() async {
    final petId = _selectedPetId?.trim() ?? '';
    if (petId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a pet before uploading documents.'),
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() => _isUploadingAttachments = true);

      final uploads = <EditableAttachmentModel>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        final uploaded = await _attachmentUploadService.uploadPetDocument(
          bytes: bytes,
          petId: petId,
          fileName: file.name,
          category: 'events',
        );
        uploads.add(EditableAttachmentModel.fromUploaded(uploaded));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _attachedDocuments.addAll(uploads);
        _didTouchAttachments = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachments = false);
      }
    }
  }

  void _removeAttachmentAt(int index) {
    if (index < 0 || index >= _attachedDocuments.length) {
      return;
    }

    setState(() {
      _attachedDocuments.removeAt(index);
      _didTouchAttachments = true;
    });
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
    final isEditing =
        _editingEventId != null && _editingEventId!.trim().isNotEmpty;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerFormTap(),
      child: AddFlowScaffold(
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
      ),
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
            eventController: _eventController,
            priceController: _priceController,
            providerController: _providerController,
            clinicController: _clinicController,
            followUpDateController: _followUpDateController,
            onPickFollowUpDate: _pickFollowUpDate,
            descriptionController: _descriptionController,
            onAddAttachment: _pickAndUploadAttachment,
            attachmentNames: _attachedDocuments
                .map((attachment) => attachment.fileName)
                .toList(growable: false),
            onRemoveAttachment: _removeAttachmentAt,
            isUploadingAttachments:
                _isUploadingAttachments || _isLoadingExistingAttachments,
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
            attachmentNames: _attachedDocuments
                .map((attachment) => attachment.fileName)
                .toList(growable: false),
          ),
        ];
    }
  }
}
