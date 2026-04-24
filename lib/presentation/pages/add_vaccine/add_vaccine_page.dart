import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/models/vaccine_model.dart';
import 'package:flutter_frontend/core/services/attachment_upload_coordinator.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/utils/date_input.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_scaffold.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_basic.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_details.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/widgets/add_vaccine_step_overview.dart';
import 'add_vaccine_args.dart';

enum _AttachmentSource { files, camera }

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
  final _petNameController = TextEditingController();
  final _administeredByController = TextEditingController();

  final VaccineService _vaccineService = VaccineService();
  final PetService _petService = PetService();
  final AttachmentUploadCoordinator _attachmentUploadCoordinator =
      AttachmentUploadCoordinator();
  final ImagePicker _imagePicker = ImagePicker();
  final List<VaccineModel> _vaccines = [];
  final List<PetModel> _pets = [];

  bool _isLoadingVaccines = false;
  bool _isLoadingPets = false;
  bool _isSubmitting = false;
  bool _didHydrateExistingAttachments = false;
  bool _didTouchAttachments = false;
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
    _attachmentUploadCoordinator.addListener(_handleAttachmentUploadsChanged);
    _applyPrefill(widget.prefill);
    _loadVaccines();
    _loadPets();
    _loadEditingVaccinationIfNeeded();
  }

  @override
  void dispose() {
    _attachmentUploadCoordinator.removeListener(
      _handleAttachmentUploadsChanged,
    );
    _attachmentUploadCoordinator.dispose();
    _dateController.dispose();
    _vaccineController.dispose();
    _productController.dispose();
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

    final existingAttachments =
        (prefill.attachedDocuments ?? const <PetDocumentModel>[])
            .map(
              (document) => EditableAttachmentModel(
                fileName: document.fileName,
                fileUri: document.fileUri,
                documentId: document.documentId,
              ),
            )
            .toList(growable: false);
    _attachmentUploadCoordinator.initializeFromExisting(existingAttachments);
    _didHydrateExistingAttachments = existingAttachments.isNotEmpty;

    if (_vaccines.isNotEmpty) {
      _applyVaccineSelectionFromPrefill(prefill);
    }
    if (_pets.isNotEmpty) {
      _applyPetSelectionFromPrefill(prefill);
    }
  }

  Future<void> _loadEditingVaccinationIfNeeded({bool force = false}) async {
    final vaccinationId = _editingVaccinationId?.trim() ?? '';
    final petId = _selectedPetId?.trim() ?? widget.prefill?.petId?.trim() ?? '';
    if (vaccinationId.isEmpty || petId.isEmpty) {
      return;
    }

    if (!force && (_didTouchAttachments || _didHydrateExistingAttachments)) {
      return;
    }

    try {
      final vaccination = await _petService.getVaccination(
        petId: petId,
        vaccinationId: vaccinationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (_administeredByController.text.trim().isEmpty) {
          _administeredByController.text = vaccination.administeredBy.trim();
        }

        _attachmentUploadCoordinator.initializeFromExisting(
          vaccination.attachedDocuments
              .map(
                (document) => EditableAttachmentModel(
                  fileName: document.fileName,
                  fileUri: document.fileUri,
                  documentId: document.documentId,
                ),
              )
              .toList(growable: false),
        );
        _didHydrateExistingAttachments = true;
      });
    } catch (_) {
      // Keep the form usable even if hydration fails.
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    } finally {
      if (mounted) {
        setState(() => _isLoadingVaccines = false);
      }
    }
  }

  Future<void> _loadPets() async {
    setState(() => _isLoadingPets = true);
    try {
      final pets = await _petService.getPets();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
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
        orElse: () => const VaccineModel(id: '', schema: '', name: ''),
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
        orElse: () => const VaccineModel(id: '', schema: '', name: ''),
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

  Future<void> _continue() async {
    AppFormSanitizers.trimControllers([
      _vaccineController,
      _productController,
      _petNameController,
      _administeredByController,
    ]);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_step == 0 &&
        _editingVaccinationId != null &&
        _editingVaccinationId!.trim().isNotEmpty &&
        !_didTouchAttachments &&
        !_didHydrateExistingAttachments) {
      await _loadEditingVaccinationIfNeeded(force: true);
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

    AppFormSanitizers.trimControllers([
      _vaccineController,
      _productController,
      _petNameController,
      _administeredByController,
    ]);

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

    if (!_attachmentUploadCoordinator.canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish uploading or remove failed attachments before saving.',
          ),
        ),
      );
      return;
    }

    final dateGiven = parseDateInput(_dateController.text.trim());
    if (dateGiven == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid date.')));
      return;
    }

    _submitToApi(dateGiven);
  }

  Future<void> _submitToApi(DateTime dateGiven) async {
    setState(() => _isSubmitting = true);

    try {
      if (_editingVaccinationId != null &&
          _editingVaccinationId!.trim().isNotEmpty &&
          !_didTouchAttachments &&
          !_didHydrateExistingAttachments) {
        await _loadEditingVaccinationIfNeeded(force: true);
      }

      if (_editingVaccinationId != null &&
          _editingVaccinationId!.trim().isNotEmpty &&
          !_didTouchAttachments &&
          !_didHydrateExistingAttachments) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not load the existing documents for this vaccine yet. Please try again in a moment.',
            ),
          ),
        );
        return;
      }

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
        'nextDueDate': nextDueDate == null
            ? null
            : formatDateForApi(nextDueDate),
        'lotNumber': '',
        'status': 'completed',
        'administeredBy': _administeredByController.text.trim(),
        'clinicName': '',
        'attachedDocuments': _attachmentUploadCoordinator
            .buildSucceededPayload()
            .map((attachment) => attachment.toPayload())
            .toList(growable: false),
      };

      if (widget.prefill == null) {
        await _petService.addVaccination(petId: _selectedPetId!, data: payload);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
      final source = await _showAttachmentSourcePicker();
      if (source == null) {
        return;
      }

      final uploads = switch (source) {
        _AttachmentSource.files => await _pickFilesForAttachment(),
        _AttachmentSource.camera => await _capturePhotoForAttachment(),
      };

      if (uploads.isEmpty || !mounted) {
        return;
      }

      _didTouchAttachments = true;
      _startAttachmentUploads(petId: petId, uploads: uploads);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    }
  }

  void _startAttachmentUploads({
    required String petId,
    required List<PendingAttachmentUpload> uploads,
  }) {
    unawaited(
      _attachmentUploadCoordinator
          .enqueueUploads(petId: petId, uploads: uploads)
          .then((_) {
            if (!mounted) {
              return;
            }
            setState(() {});
          })
          .catchError((_) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.errorGeneric)),
            );
          }),
    );
  }

  Future<_AttachmentSource?> _showAttachmentSourcePicker() {
    return showModalBottomSheet<_AttachmentSource>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text(AppStrings.attachmentSelectFile),
                subtitle: const Text(AppStrings.attachmentSelectFileSubtitle),
                onTap: () =>
                    Navigator.pop(bottomSheetContext, _AttachmentSource.files),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text(AppStrings.attachmentTakePhoto),
                subtitle: const Text(AppStrings.attachmentTakePhotoSubtitle),
                onTap: () =>
                    Navigator.pop(bottomSheetContext, _AttachmentSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<PendingAttachmentUpload>> _pickFilesForAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return const <PendingAttachmentUpload>[];
    }

    if (!mounted) {
      return const <PendingAttachmentUpload>[];
    }

    final uploads = <PendingAttachmentUpload>[];
    for (var index = 0; index < result.files.length; index++) {
      final file = result.files[index];
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      uploads.add(
        PendingAttachmentUpload(
          localId: _buildAttachmentLocalId(fileName: file.name, index: index),
          fileName: file.name,
          bytes: bytes,
          category: 'vaccinations',
          isImage: _isImageFile(file.name),
        ),
      );
    }

    return uploads;
  }

  Future<List<PendingAttachmentUpload>> _capturePhotoForAttachment() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (photo == null) {
      return const <PendingAttachmentUpload>[];
    }

    final bytes = await photo.readAsBytes();
    if (bytes.isEmpty) {
      return const <PendingAttachmentUpload>[];
    }

    if (!mounted) {
      return const <PendingAttachmentUpload>[];
    }

    return <PendingAttachmentUpload>[
      PendingAttachmentUpload(
        localId: _buildAttachmentLocalId(fileName: photo.name),
        fileName: photo.name,
        bytes: bytes,
        category: 'vaccinations',
        isImage: true,
      ),
    ];
  }

  void _removeAttachment(String localId) {
    _didTouchAttachments = true;
    _attachmentUploadCoordinator.remove(localId);
  }

  Future<void> _retryAttachment(String localId) async {
    _didTouchAttachments = true;
    await _attachmentUploadCoordinator.retry(localId);
  }

  void _handleAttachmentUploadsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _buildAttachmentLocalId({required String fileName, int? index}) {
    final suffix = index == null ? '' : '_$index';
    return '${DateTime.now().microsecondsSinceEpoch}${suffix}_$fileName';
  }

  bool _isImageFile(String fileName) {
    final normalized = fileName.toLowerCase();
    return normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp');
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
            selectedVaccineId: _selectedVaccineId,
            selectedPetName: _selectedPetName,
            selectedPetId: _selectedPetId,
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

                if (value == null || value.trim().isEmpty) {
                  return;
                }

                final matches = _vaccines
                    .where((vaccine) => vaccine.name == value)
                    .toList(growable: false);
                if (matches.length == 1) {
                  _selectedVaccineId = matches.first.id;
                }
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
                    orElse: () =>
                        const VaccineModel(id: '', schema: '', name: ''),
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
            onAddAttachment: _pickAndUploadAttachment,
            attachments: _attachmentUploadCoordinator.items,
            onRemoveAttachment: _removeAttachment,
            onRetryAttachment: _retryAttachment,
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
            attachmentNames: _attachmentUploadCoordinator.items
                .map((attachment) => attachment.fileName)
                .toList(growable: false),
          ),
        ];
    }
  }
}
