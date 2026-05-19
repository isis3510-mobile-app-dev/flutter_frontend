import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/forms/app_form_utils.dart';
import '../../../../core/models/lost_pet_model.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/app_image_cache_manager.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/lost_pet_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/widgets/lost_pet_map_preview.dart';
import '../../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../models/pet_ui_model.dart';

class LostModeFormPage extends StatefulWidget {
  const LostModeFormPage({super.key, required this.pet});

  final PetUiModel pet;

  @override
  State<LostModeFormPage> createState() => _LostModeFormPageState();
}

class _LostModeFormPageState extends State<LostModeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final LostPetService _lostPetService = LostPetService();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  final _noteController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  LostPetReportModel? _existingReport;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isResolving = false;
  bool _nfcNotificationsEnabled = true;
  bool _allowCall = false;
  bool _allowWhatsApp = false;
  bool _exposeMedicalInfo = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _lostPetService.getOwnerLostReport(widget.pet.id),
        _userService.getCurrentUser(),
      ]);
      final report = results[0] as LostPetReportModel?;
      final user = results[1] as UserProfile;

      if (!mounted) {
        return;
      }

      final activeReport = report?.isActive == true ? report : null;
      _existingReport = activeReport;
      if (activeReport != null) {
        _noteController.text = activeReport.lostNote;
        _locationNameController.text = activeReport.lastSeen.name;
        _latitudeController.text =
            activeReport.lastSeen.latitude?.toStringAsFixed(6) ?? '';
        _longitudeController.text =
            activeReport.lastSeen.longitude?.toStringAsFixed(6) ?? '';
        final primaryContact = activeReport.primaryContact;
        _contactNameController.text = primaryContact?.name ?? user.name;
        _contactPhoneController.text = primaryContact?.phone ?? user.phone;
        _allowCall = primaryContact?.allowCall ?? true;
        _allowWhatsApp = primaryContact?.allowWhatsApp ?? true;
        _exposeMedicalInfo = activeReport.exposeMedicalInfo;
        _nfcNotificationsEnabled = activeReport.nfcNotificationsEnabled;
      } else {
        _contactNameController.text = user.name;
        _contactPhoneController.text = user.phone;
      }
    } catch (_) {
      // The form can still be filled manually.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _latitudeController.text = location.latitude.toStringAsFixed(6);
        _longitudeController.text = location.longitude.toStringAsFixed(6);
        _locationNameController.text = 'Current phone location';
      });
    } on LocationServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.lostPetLocationUnavailable)),
      );
    }
  }

  Future<void> _saveLostMode() async {
    AppFormSanitizers.trimControllers([
      _noteController,
      _locationNameController,
      _latitudeController,
      _longitudeController,
      _contactNameController,
      _contactPhoneController,
    ]);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'city': 'Bogotá',
      'lostNote': _noteController.text.trim(),
      'lastSeenLocation': _lastSeenLocationLabel(),
      'lastSeenLatitude': double.tryParse(_latitudeController.text.trim()),
      'lastSeenLongitude': double.tryParse(_longitudeController.text.trim()),
      'lastSeenAt': DateTime.now().toIso8601String(),
      'exposeMedicalInfo': _exposeMedicalInfo,
      'nfcNotificationsEnabled': _nfcNotificationsEnabled,
      'emergencyContacts': [
        {
          'name': _contactNameController.text.trim(),
          'phone': _contactPhoneController.text.trim(),
          'whatsapp': _contactPhoneController.text.trim(),
          'relationship': 'Owner',
          'preferred': true,
          'exposePhone': _allowCall,
          'exposeWhatsapp': _allowWhatsApp,
        },
      ],
      'petName': widget.pet.name,
      'species': widget.pet.species,
      'breed': widget.pet.breed,
      'gender': widget.pet.gender,
      'color': widget.pet.color,
      'weight': widget.pet.weight,
      'photoUrl': widget.pet.photoUrl,
      'knownAllergies': widget.pet.knownAllergies,
      'defaultVet': widget.pet.defaultVet,
      'defaultClinic': widget.pet.defaultClinic,
    };

    try {
      await _lostPetService.saveOwnerLostReport(
        petId: widget.pet.id,
        data: payload,
        isUpdate: _existingReport != null,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.lostModeSaved)));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.petsLoadError)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markFound() async {
    setState(() {
      _isResolving = true;
    });

    try {
      await _lostPetService.markPetAsFound(widget.pet.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.lostModeFound)));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.petsLoadError)));
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  String? _requiredValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Required field.' : null;
  }

  String? _phoneValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required field.';
    }
    return AppFormValidators.phone(
      maxLength: 20,
      invalidMessage: 'Invalid phone number.',
    ).call(value);
  }

  String? _latitudeValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    final longitude = _longitudeController.text.trim();
    if (trimmed.isEmpty && longitude.isEmpty) {
      return null;
    }
    if (trimmed.isEmpty) {
      return 'Latitude required.';
    }
    final latitude = double.tryParse(trimmed);
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'Invalid latitude.';
    }
    return null;
  }

  String? _longitudeValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    final latitude = _latitudeController.text.trim();
    if (trimmed.isEmpty && latitude.isEmpty) {
      return null;
    }
    if (trimmed.isEmpty) {
      return 'Longitude required.';
    }
    final longitude = double.tryParse(trimmed);
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'Invalid longitude.';
    }
    return null;
  }

  void _setMapPoint(LostPetMapPoint point) {
    setState(() {
      _latitudeController.text = point.latitude.toStringAsFixed(6);
      _longitudeController.text = point.longitude.toStringAsFixed(6);
      _locationNameController.text = 'Selected map point';
    });
  }

  double? _readCoordinate(TextEditingController controller) {
    return double.tryParse(controller.text.trim());
  }

  String _lastSeenLocationLabel() {
    final existingLabel = _locationNameController.text.trim();
    if (existingLabel.isNotEmpty) {
      return existingLabel;
    }
    if (_readCoordinate(_latitudeController) != null &&
        _readCoordinate(_longitudeController) != null) {
      return 'Selected map point';
    }
    return '';
  }

  void _handleBottomNavTap(int index) {
    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  void _showExtraContactsComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Additional contacts are coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveLostReport = _existingReport?.isActive == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.lostModeTitle),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveLostMode,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceM,
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceXXXL,
                  ),
                  children: [
                    _PetHero(pet: widget.pet),
                    const SizedBox(height: AppDimensions.spaceM),
                    _LostStatusCard(
                      hasActiveLostReport: hasActiveLostReport,
                      isResolving: _isResolving,
                      onMarkFound: _markFound,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _LostSettingsCard(
                      enabled: _nfcNotificationsEnabled,
                      exposeMedicalInfo: _exposeMedicalInfo,
                      hasMedicalInfo: widget.pet.knownAllergies
                          .trim()
                          .isNotEmpty,
                      onChanged: (value) {
                        setState(() => _nfcNotificationsEnabled = value);
                      },
                      onExposeMedicalInfoChanged: (value) {
                        setState(() => _exposeMedicalInfo = value);
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _EmergencyContactCard(
                      contactNameController: _contactNameController,
                      contactPhoneController: _contactPhoneController,
                      phoneValidator: _phoneValidator,
                      nameValidator: _requiredValidator,
                      onAddTap: _showExtraContactsComingSoon,
                      allowCall: _allowCall,
                      allowWhatsApp: _allowWhatsApp,
                      onAllowCallChanged: (value) {
                        setState(() => _allowCall = value);
                      },
                      onAllowWhatsAppChanged: (value) {
                        setState(() => _allowWhatsApp = value);
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _NoteCard(controller: _noteController),
                    const SizedBox(height: AppDimensions.spaceM),
                    _MapCard(
                      latitude: _readCoordinate(_latitudeController),
                      longitude: _readCoordinate(_longitudeController),
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      latitudeValidator: _latitudeValidator,
                      longitudeValidator: _longitudeValidator,
                      onUseCurrentLocation: _useCurrentLocation,
                      onPointSelected: _setMapPoint,
                      onManualCoordinateChanged: () => setState(() {}),
                      hasSelectedLocation:
                          _readCoordinate(_latitudeController) != null &&
                          _readCoordinate(_longitudeController) != null,
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExtraContactsComingSoon,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: 2,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}

class _PetHero extends StatelessWidget {
  const _PetHero({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 7.5,
        child: _PetImage(pet: pet),
      ),
    );
  }
}

class _LostStatusCard extends StatelessWidget {
  const _LostStatusCard({
    required this.hasActiveLostReport,
    required this.isResolving,
    required this.onMarkFound,
  });

  final bool hasActiveLostReport;
  final bool isResolving;
  final VoidCallback onMarkFound;

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primaryVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActiveLostReport
                  ? Icons.location_on_outlined
                  : Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveLostReport ? 'Lost mode is active' : 'Pet is Safe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasActiveLostReport
                      ? 'Tap to mark this pet as found'
                      : 'Tap save to activate lost mode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Switch(
            value: hasActiveLostReport,
            onChanged: hasActiveLostReport && !isResolving
                ? (_) => onMarkFound()
                : null,
          ),
        ],
      ),
    );
  }
}

class _LostSettingsCard extends StatelessWidget {
  const _LostSettingsCard({
    required this.enabled,
    required this.exposeMedicalInfo,
    required this.hasMedicalInfo,
    required this.onChanged,
    required this.onExposeMedicalInfoChanged,
  });

  final bool enabled;
  final bool exposeMedicalInfo;
  final bool hasMedicalInfo;
  final ValueChanged<bool> onChanged;
  final ValueChanged<bool> onExposeMedicalInfoChanged;

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      title: 'Lost mode settings',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEBFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  color: AppColors.petQuickActionNfc,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Scan Notifications',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Get notified when someone scans your pet's tag",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          if (hasMedicalInfo) ...[
            const Divider(height: AppDimensions.spaceXL),
            Row(
              children: [
                const Icon(
                  Icons.medical_information_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Show allergy info publicly',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
                Switch(
                  value: exposeMedicalInfo,
                  onChanged: onExposeMedicalInfoChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.contactNameController,
    required this.contactPhoneController,
    required this.nameValidator,
    required this.phoneValidator,
    required this.onAddTap,
    required this.allowCall,
    required this.allowWhatsApp,
    required this.onAllowCallChanged,
    required this.onAllowWhatsAppChanged,
  });

  final TextEditingController contactNameController;
  final TextEditingController contactPhoneController;
  final FormFieldValidator<String> nameValidator;
  final FormFieldValidator<String> phoneValidator;
  final VoidCallback onAddTap;
  final bool allowCall;
  final bool allowWhatsApp;
  final ValueChanged<bool> onAllowCallChanged;
  final ValueChanged<bool> onAllowWhatsAppChanged;

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      title: AppStrings.lostPetEmergencyContacts,
      trailing: TextButton.icon(
        onPressed: onAddTap,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primaryVariant,
          foregroundColor: AppColors.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: contactNameController,
            validator: nameValidator,
            decoration: _inputDecoration(
              context,
              labelText: AppStrings.lostModeContactName,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          TextFormField(
            controller: contactPhoneController,
            validator: phoneValidator,
            keyboardType: TextInputType.phone,
            inputFormatters: AppInputFormatters.phone(),
            decoration: _inputDecoration(
              context,
              labelText: AppStrings.lostModeContactPhone,
            ),
          ),
          const Divider(height: AppDimensions.spaceXL),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: allowCall,
            onChanged: onAllowCallChanged,
            title: const Text('Show phone for calls'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: allowWhatsApp,
            onChanged: onAllowWhatsAppChanged,
            title: const Text('Show WhatsApp contact'),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      title: AppStrings.lostModeNoteLabel,
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 7,
        maxLength: 500,
        decoration: _inputDecoration(
          context,
          hintText: AppStrings.lostModeNoteHint,
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.latitude,
    required this.longitude,
    required this.latitudeController,
    required this.longitudeController,
    required this.latitudeValidator,
    required this.longitudeValidator,
    required this.onUseCurrentLocation,
    required this.onPointSelected,
    required this.onManualCoordinateChanged,
    required this.hasSelectedLocation,
  });

  final double? latitude;
  final double? longitude;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final FormFieldValidator<String> latitudeValidator;
  final FormFieldValidator<String> longitudeValidator;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<LostPetMapPoint> onPointSelected;
  final VoidCallback onManualCoordinateChanged;
  final bool hasSelectedLocation;

  @override
  Widget build(BuildContext context) {
    return _ModeCard(
      title: AppStrings.lostModeLocationLabel,
      trailing: TextButton.icon(
        onPressed: onUseCurrentLocation,
        icon: const Icon(Icons.my_location_rounded, size: 16),
        label: const Text('Use current'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LostPetMapPreview(
            height: 210,
            latitude: latitude,
            longitude: longitude,
            onPointSelected: onPointSelected,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: latitudeController,
                  validator: latitudeValidator,
                  onChanged: (_) => onManualCoordinateChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Latitude',
                    hintText: '4.711000',
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: TextFormField(
                  controller: longitudeController,
                  validator: longitudeValidator,
                  onChanged: (_) => onManualCoordinateChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Longitude',
                    hintText: '-74.072100',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Icon(
                hasSelectedLocation
                    ? Icons.check_circle_rounded
                    : Icons.touch_app_rounded,
                size: 18,
                color: hasSelectedLocation
                    ? AppColors.primary
                    : AppColors.grey700,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  hasSelectedLocation
                      ? 'Location selected'
                      : 'Tap the online map or enter coordinates manually',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasSelectedLocation
                        ? AppColors.primary
                        : AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({this.title, this.trailing, required this.child});

  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark
            : AppColors.petCardBackground,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceDark.withValues(alpha: 0.72)
                          : AppColors.grey700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
          ],
          child,
        ],
      ),
    );
  }
}

class _PetImage extends StatelessWidget {
  const _PetImage({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = pet.effectivePhotoPath?.trim();
    if (value == null || value.isEmpty) {
      return _PetImagePlaceholder(isDark: isDark);
    }

    if (pet.isPhotoRemote) {
      return CachedNetworkImage(
        imageUrl: value,
        cacheManager: AppImageCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (_, _) => _PetImagePlaceholder(isDark: isDark),
        errorWidget: (_, _, _) => _PetImagePlaceholder(isDark: isDark),
      );
    }

    return Image.file(
      File(value),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _PetImagePlaceholder(isDark: isDark),
    );
  }
}

class _PetImagePlaceholder extends StatelessWidget {
  const _PetImagePlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? AppColors.petCardQuickActionBgDark
          : AppColors.petCardQuickActionBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.pets_rounded,
        size: AppDimensions.iconXL,
        color: isDark
            ? AppColors.quickActionIconTintDark
            : AppColors.quickActionIconTint,
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? AppColors.secondaryDark : AppColors.secondary;
  final borderColor = isDark ? AppColors.grey700 : AppColors.grey500;
  final hintColor = isDark
      ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
      : AppColors.grey500;

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: hintColor,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: _inputBorder(borderColor),
    focusedBorder: _focusedInputBorder,
    disabledBorder: _inputBorder(borderColor),
    errorBorder: _errorInputBorder,
    focusedErrorBorder: _errorInputBorder,
  );
}

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: const BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: color, width: 1.5),
);

const OutlineInputBorder _focusedInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
);

const OutlineInputBorder _errorInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.error, width: 1.5),
);
