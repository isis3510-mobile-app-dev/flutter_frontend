import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/presentation/widgets/stepper.dart' as app_stepper;
import 'package:flutter_frontend/shared/widgets/form_field.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

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
  final _followUpDateController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _petNameController = TextEditingController();
  final _clinicProviderController = TextEditingController();

  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final List<PetModel> _pets = [];

  bool _isLoadingPets = false;
  bool _isSubmitting = false;

  String? _selectedPetName;
  String? _selectedPetId;
  String? _ownerId;
  String? _originalEventType;

  AddEventArgs? _pendingPrefill;

  int _step = 0;

  bool get _isEditing {
    final eventId = widget.prefill?.eventId?.trim() ?? '';
    return eventId.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill);
    _loadPets();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _followUpDateController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _petNameController.dispose();
    _clinicProviderController.dispose();
    super.dispose();
  }

  void _applyPrefill(AddEventArgs? prefill) {
    if (prefill == null) {
      return;
    }

    _pendingPrefill = prefill;

    final ownerId = prefill.ownerId?.trim() ?? '';
    if (ownerId.isNotEmpty) {
      _ownerId = ownerId;
    }

    final eventName = prefill.eventName?.trim() ?? '';
    if (eventName.isNotEmpty) {
      _eventController.text = eventName;
    }

    final description = prefill.description?.trim() ?? '';
    if (description.isNotEmpty) {
      _descriptionController.text = description;
    }

    final provider = prefill.provider?.trim() ?? '';
    final clinic = prefill.clinic?.trim() ?? '';
    final clinicProvider = provider.isNotEmpty ? provider : clinic;
    if (clinicProvider.isNotEmpty) {
      _clinicProviderController.text = clinicProvider;
    }

    final eventType = prefill.eventType?.trim() ?? '';
    if (eventType.isNotEmpty) {
      _originalEventType = eventType;
    }

    if (prefill.dateTime != null) {
      _dateController.text = _formatDateForInput(prefill.dateTime!);
      _timeController.text = _formatTimeForInput(prefill.dateTime!);
    }

    if (prefill.followUpDate != null) {
      _followUpDateController.text = _formatDateForInput(prefill.followUpDate!);
    }

    if (prefill.price != null) {
      _priceController.text = _formatPriceForInput(prefill.price!);
    }

    final petId = prefill.petId?.trim() ?? '';
    if (petId.isNotEmpty) {
      _selectedPetId = petId;
    }

    final petName = prefill.petName?.trim() ?? '';
    if (petName.isNotEmpty) {
      _selectedPetName = petName;
      _petNameController.text = petName;
    }

    if (_pets.isNotEmpty) {
      _applyPetSelectionFromPrefill(prefill);
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
          // Skip invalid pets and keep loading the rest.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _ownerId ??= profile.id.trim();

        _pets
          ..clear()
          ..addAll(pets);

        if (_pendingPrefill != null) {
          _applyPetSelectionFromPrefill(_pendingPrefill!);
        }
      });
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

  void _applyPetSelectionFromPrefill(AddEventArgs prefill) {
    if (_pets.isEmpty) {
      return;
    }

    final petId = prefill.petId?.trim() ?? '';
    if (petId.isNotEmpty) {
      final match = _pets.firstWhere(
        (pet) => pet.id == petId,
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

    final petName = prefill.petName?.trim() ?? '';
    if (petName.isNotEmpty) {
      final match = _pets.firstWhere(
        (pet) => pet.name == petName,
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
    _selectedPetId = pet.id;
    _selectedPetName = pet.name;
    _petNameController.text = pet.name;
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

  List<String> get _petNameOptions {
    final names = _pets
        .map((pet) => pet.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  String? get _selectedPetDropdownValue {
    if (_selectedPetName == null) {
      return null;
    }

    if (_petNameOptions.contains(_selectedPetName)) {
      return _selectedPetName;
    }

    return null;
  }

  Future<void> _pickDate() async {
    final initialDate = _parseDateInput(_dateController.text.trim()) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    _dateController.text = _formatDateForInput(pickedDate);
  }

  Future<void> _pickTime() async {
    final initialTime = _parseTimeInput(_timeController.text.trim()) ?? TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) {
      return;
    }

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    _timeController.text = '$hour:$minute';
  }

  Future<void> _pickFollowUpDate() async {
    final initialDate = _parseDateInput(_followUpDateController.text.trim()) ??
        _parseDateInput(_dateController.text.trim()) ??
        DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    _followUpDateController.text = _formatDateForInput(pickedDate);
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

    final date = _parseDateInput(_dateController.text.trim());
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid date.')),
      );
      return;
    }

    final time = _parseTimeInput(_timeController.text.trim());
    if (time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid time.')),
      );
      return;
    }

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    _submitToApi(dateTime);
  }

  Future<void> _submitToApi(DateTime dateTime) async {
    setState(() => _isSubmitting = true);

    try {
      final eventName = _eventController.text.trim();
      final providerOrClinic = _clinicProviderController.text.trim();
      final parsedPrice = _parsePriceInput(_priceController.text.trim());

      final followUpDateOnly = _parseDateInput(_followUpDateController.text.trim());
      final followUpDate = followUpDateOnly == null
          ? null
          : DateTime(
              followUpDateOnly.year,
              followUpDateOnly.month,
              followUpDateOnly.day,
              dateTime.hour,
              dateTime.minute,
            );

      final originalEventName = widget.prefill?.eventName?.trim() ?? '';
      final keepOriginalType = _isEditing &&
          eventName == originalEventName &&
          (_originalEventType?.trim().isNotEmpty ?? false);
      final eventType = keepOriginalType
          ? _originalEventType!.trim()
          : _buildEventType(eventName);

      final payload = <String, dynamic>{
        'pet_id': _selectedPetId,
        'title': eventName,
        'event_type': eventType,
        'date': dateTime.toUtc().toIso8601String(),
        'price': parsedPrice,
        'provider': providerOrClinic,
        'clinic': providerOrClinic,
        'description': _descriptionController.text.trim(),
        'follow_up_date': followUpDate?.toUtc().toIso8601String(),
      };

      final normalizedOwnerId = (_ownerId ?? '').trim();
      if (normalizedOwnerId.isNotEmpty) {
        payload['owner_id'] = normalizedOwnerId;
      }

      if (_isEditing) {
        final attachedDocuments = widget.prefill?.attachedDocuments ?? const [];
        if (attachedDocuments.isNotEmpty) {
          payload['attached_documents'] = attachedDocuments
              .map(
                (document) => {
                  'document_id': document.documentId,
                  'file_name': document.fileName,
                  'file_uri': document.fileUri,
                },
              )
              .toList(growable: false);
        }

        await _eventService.updateEvent(
          eventId: widget.prefill!.eventId!.trim(),
          data: payload,
        );
      } else {
        await _eventService.createEvent(payload);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Event updated successfully.'
                : 'Event saved successfully.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
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

  @override
  Widget build(BuildContext context) {
    final stepContent = _buildStepContent();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : AppStrings.addEventTitle),
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
                    AppStrings.stepOverview,
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
                      ? (_isSubmitting
                          ? (_isEditing ? 'Updating...' : 'Saving...')
                          : (_isEditing ? 'Update Event' : AppStrings.semanticAddEventButton))
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
            label: '${AppStrings.labelEventName} *',
            hintText: AppStrings.hintEventName,
            controller: _eventController,
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
            label: '${AppStrings.labelEventTime} *',
            hintText: AppStrings.hintEventTime,
            icon: Icons.access_time_outlined,
            controller: _timeController,
            readOnly: true,
            onTap: _pickTime,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.validationRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _AppDropdownField(
            label: '${AppStrings.labelPetName} *',
            hintText: _isLoadingPets
                ? 'Loading pets...'
                : _petNameOptions.isEmpty
                    ? 'No pets available'
                    : AppStrings.hintPetName,
            value: _selectedPetDropdownValue,
            items: _petNameOptions,
            enabled: !_isLoadingPets && _petNameOptions.isNotEmpty,
            onChanged: (value) {
              setState(() {
                _selectedPetName = value;
                _petNameController.text = value ?? '';

                if (value == null) {
                  _selectedPetId = null;
                  return;
                }

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
            label: 'Price',
            hintText: 'e.g. 120.50',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: _priceController,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }

              if (_parsePriceInput(text) == null) {
                return 'Enter a valid price.';
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: 'Follow-up Date',
            hintText: AppStrings.hintDate,
            icon: Icons.event_repeat_outlined,
            controller: _followUpDateController,
            readOnly: true,
            onTap: _pickFollowUpDate,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }

              if (_parseDateInput(text) == null) {
                return AppStrings.validationInvalidDate;
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelClinicProvider,
            hintText: AppStrings.hintClinicProvider,
            controller: _clinicProviderController,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelDescription,
            hintText: AppStrings.hintEventDescription,
            controller: _descriptionController,
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
            label: AppStrings.labelEventName,
            hintText: AppStrings.hintNotProvided,
            controller: _eventController,
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
            label: AppStrings.labelEventTime,
            hintText: AppStrings.hintNotProvided,
            controller: _timeController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: 'Price',
            hintText: AppStrings.hintNotProvided,
            controller: _priceController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: 'Follow-up Date',
            hintText: AppStrings.hintNotProvided,
            controller: _followUpDateController,
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
            label: AppStrings.labelClinicProvider,
            hintText: AppStrings.hintNotProvided,
            controller: _clinicProviderController,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          AppFormField(
            label: AppStrings.labelDescription,
            hintText: AppStrings.hintNotProvided,
            controller: _descriptionController,
            readOnly: true,
          ),
        ];
    }
  }
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

String _formatDateForInput(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String _formatTimeForInput(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatPriceForInput(double price) {
  final fixed = price.toStringAsFixed(2);
  if (fixed.endsWith('00')) {
    return fixed.substring(0, fixed.length - 3);
  }
  if (fixed.endsWith('0')) {
    return fixed.substring(0, fixed.length - 1);
  }
  return fixed;
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

double? _parsePriceInput(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

String _buildEventType(String title) {
  final normalized = title.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'general';
  }

  var slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  slug = slug.replaceAll(RegExp(r'_+'), '_');
  slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');

  if (slug.isEmpty) {
    return 'general';
  }

  if (slug.length > 100) {
    return slug.substring(0, 100);
  }

  return slug;
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
