import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/nfc_backend_service.dart';
import '../../../core/services/nfc_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/telemetry_service.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../pets/models/pet_ui_mapper.dart';
import '../pets/models/pet_ui_model.dart';
import 'widgets/nfc_data_toggle.dart';
import 'widgets/nfc_header_graphic.dart';
import 'widgets/nfc_status_banner.dart';

enum _NfcMode { read, write }

enum _NfcViewState { setup, scanning, success }

class NfcPage extends StatefulWidget {
  const NfcPage({super.key, this.initialPetId});

  final String? initialPetId;

  @override
  State<NfcPage> createState() => _NfcPageState();
}

class _NfcPageState extends State<NfcPage> {
  static const _currentBottomIndex = 0;

  final NfcService _nfcService = NfcService();
  final NfcBackendService _nfcBackendService = NfcBackendService();
  final PetService _petService = PetService();
  final TelemetryService _telemetryService = TelemetryService();

  List<PetUiModel> _pets = const [];
  String? _selectedPetId;

  bool _isLoadingPets = false;
  String? _petsLoadErrorMessage;
  bool? _isNfcAvailable;

  _NfcMode _mode = _NfcMode.read;
  _NfcViewState _viewState = _NfcViewState.setup;

  bool _includeOwnerContact = true;
  bool _includeEmergencyInfo = true;

  String? _operationErrorMessage;
  String? _lastReadRawPayload;
  Map<String, dynamic>? _lastReadTagData;
  Map<String, dynamic>? _lastWrittenTagData;
  DateTime? _nfcReadStart;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _loadPets();
  }

  Future<void> _checkNfcAvailability() async {
    // NFC manager is only expected to work on Android/iOS devices.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNfcAvailable = false;
      });
      return;
    }

    final available = await _nfcService.isAvailable();
    if (!mounted) {
      return;
    }

    setState(() {
      _isNfcAvailable = available;
    });
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoadingPets = true;
      _petsLoadErrorMessage = null;
    });

    try {
      final pets = await _petService.getPets();
      final mappedPets = pets
          .map((pet) => pet.toUiModel())
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _pets = mappedPets;

        if (mappedPets.isEmpty) {
          _selectedPetId = null;
        } else if (widget.initialPetId != null &&
            mappedPets.any((pet) => pet.id == widget.initialPetId)) {
          _selectedPetId = widget.initialPetId;
        } else if (_selectedPetId == null ||
            !mappedPets.any((pet) => pet.id == _selectedPetId)) {
          _selectedPetId = _pets.first.id;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pets = const [];
        _selectedPetId = null;
        _petsLoadErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pets = const [];
        _selectedPetId = null;
        _petsLoadErrorMessage = AppStrings.petsLoadError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPets = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_nfcService.stopSession());
    super.dispose();
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.featureUnavailable)),
    );
  }

  void _handleBottomNavTap(int index) {
    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      _showUnavailableMessage();
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  void _setMode(_NfcMode mode) {
    setState(() {
      _mode = mode;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
      _nfcReadStart = null;
    });
  }

  Future<void> _startScanning() async {
    if (_mode == _NfcMode.read) {
      _nfcReadStart = DateTime.now();
    }
    setState(() {
      _viewState = _NfcViewState.scanning;
      _operationErrorMessage = null;
    });

    try {
      final nfcAvailable = await _nfcService.isAvailable();
      if (mounted && _isNfcAvailable != nfcAvailable) {
        setState(() {
          _isNfcAvailable = nfcAvailable;
        });
      }

      if (!nfcAvailable) {
        if (_mode == _NfcMode.read) {
          await _simulateReadWithoutNfc();
        } else {
          await _simulateWriteWithoutNfc();
        }
        return;
      }

      if (_mode == _NfcMode.read) {
        final payload = await _nfcService.readTextTag();
        final parsedPayload = _tryParseJsonMap(payload);
        final scannedPetId = _extractPetId(
          rawPayload: payload,
          payload: parsedPayload,
        );
        Map<String, dynamic>? resolvedReadPayload = parsedPayload;

        if (scannedPetId != null && scannedPetId.isNotEmpty) {
          try {
            final backendPayload = await _nfcBackendService.readPublicTagData(
              scannedPetId,
            );
            if (backendPayload.isNotEmpty) {
              resolvedReadPayload = backendPayload;
            }
          } catch (_) {
            // Fall back to the payload stored on the tag when public read fails.
          }
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _lastReadRawPayload = payload;
          _lastReadTagData = resolvedReadPayload;
          if (scannedPetId != null &&
              _pets.any((pet) => pet.id == scannedPetId)) {
            _selectedPetId = scannedPetId;
          }
          _viewState = _NfcViewState.success;
        });
        _logNfcReadIfPossible();
        return;
      }

      final selectedPet = _selectedPet;
      if (selectedPet == null) {
        _handleNfcError(
          'You do not have pets available to write. Add a pet first.',
        );
        return;
      }

      final backendPayload = await _nfcBackendService.getWritePayload(
        selectedPet.id,
      );
      final payloadData = _applyWriteOptions(
        payload: backendPayload,
        pet: selectedPet,
      );
      await _nfcService.writeTextTag(jsonEncode(payloadData));
      await _nfcBackendService.syncPet(selectedPet.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _lastWrittenTagData = payloadData;
        _viewState = _NfcViewState.success;
      });

      unawaited(_loadPets());
    } on ApiException catch (error) {
      _handleNfcError(error.message);
    } on NfcServiceException catch (error) {
      _handleNfcError(error.message);
    } catch (_) {
      _handleNfcError(
        _mode == _NfcMode.read
            ? 'Could not read NFC tag. Please try again.'
            : 'Could not write NFC tag. Please try again.',
      );
    }
  }

  Future<void> _simulateReadWithoutNfc() async {
    final pet = _selectedPet;
    if (pet == null) {
      _handleNfcError(
        'Simulation requires at least one pet. Add a pet to continue.',
      );
      return;
    }

    final backendPayload = await _nfcBackendService.readPublicTagData(pet.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _lastReadRawPayload = jsonEncode({
        'petId': pet.id,
        'source': 'simulation',
      });
      _lastReadTagData = backendPayload;
      _selectedPetId = pet.id;
      _viewState = _NfcViewState.success;
    });
    _logNfcReadIfPossible();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation mode: read completed using backend data.'),
      ),
    );
  }

  Future<void> _simulateWriteWithoutNfc() async {
    final selectedPet = _selectedPet;
    if (selectedPet == null) {
      _handleNfcError(
        'You do not have pets available to write. Add a pet first.',
      );
      return;
    }

    final backendPayload = await _nfcBackendService.getWritePayload(
      selectedPet.id,
    );
    final payloadData = _applyWriteOptions(
      payload: backendPayload,
      pet: selectedPet,
    );
    await _nfcBackendService.syncPet(selectedPet.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _lastWrittenTagData = payloadData;
      _viewState = _NfcViewState.success;
    });

    unawaited(_loadPets());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Simulation mode: write flow completed without NFC hardware.',
        ),
      ),
    );
  }

  Future<void> _cancelScanning() async {
    await _nfcService.stopSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
      _nfcReadStart = null;
    });
  }

  void _scanAnotherTag() {
    setState(() {
      _mode = _NfcMode.read;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
      _nfcReadStart = null;
    });
  }

  void _writeAnotherTag() {
    setState(() {
      _mode = _NfcMode.write;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
      _nfcReadStart = null;
    });
  }

  void _finishWriting() {
    setState(() {
      _mode = _NfcMode.read;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
      _nfcReadStart = null;
    });
  }

  void _handleNfcError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = message;
      _nfcReadStart = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logNfcReadIfPossible() {
    final startTime = _nfcReadStart;
    if (startTime == null) {
      return;
    }
    _nfcReadStart = null;
    final endTime = DateTime.now();
    unawaited(
      _telemetryService.logNfcReadExecution(
        startTime: startTime,
        endTime: endTime,
      ),
    );
  }

  Map<String, dynamic> _applyWriteOptions({
    required Map<String, dynamic> payload,
    required PetUiModel pet,
  }) {
    final filteredPayload = Map<String, dynamic>.from(payload);

    // Keep minimum identity fields for public lookup after writing.
    filteredPayload['petId'] =
        _extractPetIdFromPayload(filteredPayload) ?? pet.id;
    filteredPayload.putIfAbsent('petName', () => pet.name);
    filteredPayload.putIfAbsent('name', () => pet.name);
    filteredPayload.putIfAbsent('species', () => pet.species);
    filteredPayload.putIfAbsent('breed', () => pet.breed);

    if (!_includeOwnerContact) {
      for (final key in const [
        'ownerName',
        'owner_name',
        'ownerPhone',
        'owner_phone',
        'ownerEmail',
        'owner_email',
        'owner',
        'contact',
      ]) {
        filteredPayload.remove(key);
      }
    }

    if (!_includeEmergencyInfo) {
      for (final key in const [
        'knownAllergies',
        'known_allergies',
        'defaultVet',
        'default_vet',
        'defaultClinic',
        'default_clinic',
        'medicalNotes',
        'medical_notes',
        'emergency',
      ]) {
        filteredPayload.remove(key);
      }
    }

    return filteredPayload;
  }

  Map<String, dynamic>? _tryParseJsonMap(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? _extractPetId({
    required String rawPayload,
    Map<String, dynamic>? payload,
  }) {
    final fromPayload = _extractPetIdFromPayload(payload);
    if (fromPayload != null && fromPayload.isNotEmpty) {
      return fromPayload;
    }

    final normalizedRawPayload = rawPayload.trim();
    if (normalizedRawPayload.isEmpty) {
      return null;
    }

    final looksLikeMongoObjectId = RegExp(
      r'^[a-fA-F0-9]{24}$',
    ).hasMatch(normalizedRawPayload);
    if (looksLikeMongoObjectId) {
      return normalizedRawPayload;
    }

    return null;
  }

  String? _extractPetIdFromPayload(Map<String, dynamic>? payload) {
    final directId = _readPayloadOptionalText(payload, const [
      'petId',
      'pet_id',
      'id',
      '_id',
    ]);
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    return _readPayloadOptionalText(payload, const [
      'pet.id',
      'pet.petId',
      'pet.pet_id',
      'pet._id',
    ]);
  }

  dynamic _readPayloadValue(Map<String, dynamic>? payload, List<String> paths) {
    if (payload == null) {
      return null;
    }

    for (final path in paths) {
      if (path.contains('.')) {
        dynamic current = payload;
        final segments = path.split('.');
        for (final segment in segments) {
          if (current is Map && current.containsKey(segment)) {
            current = current[segment];
          } else {
            current = null;
            break;
          }
        }
        if (current != null) {
          return current;
        }
        continue;
      }

      if (payload.containsKey(path)) {
        return payload[path];
      }
    }

    return null;
  }

  String? _readPayloadOptionalText(
    Map<String, dynamic>? payload,
    List<String> paths,
  ) {
    final value = _readPayloadValue(payload, paths);
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  String _readPayloadText(
    Map<String, dynamic>? payload,
    List<String> paths, {
    required String fallback,
  }) {
    final text = _readPayloadOptionalText(payload, paths);
    return text == null || text.isEmpty ? fallback : text;
  }

  PetUiModel? get _selectedPet {
    if (_pets.isEmpty) {
      return null;
    }

    final selectedPetId = _selectedPetId;
    if (selectedPetId == null || selectedPetId.isEmpty) {
      return _pets.first;
    }

    return _pets.firstWhere(
      (pet) => pet.id == selectedPetId,
      orElse: () => _pets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _NfcTopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStateContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentBottomIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildStateContent() {
    return switch (_viewState) {
      _NfcViewState.setup => _buildSetupContent(),
      _NfcViewState.scanning => _buildScanningContent(),
      _NfcViewState.success => _buildSuccessContent(),
    };
  }

  Widget _buildSetupContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReadMode = _mode == _NfcMode.read;
    final pet = _selectedPet;
    final selectedPetName = pet?.name ?? 'your pet';
    final canWriteTag = pet != null;
    final canStartNfc = isReadMode || canWriteTag;
    final isSimulationMode = _isNfcAvailable == false;
    final actionButtonText = isSimulationMode
        ? (isReadMode ? 'Test Read (Simulation)' : 'Test Write (Simulation)')
        : (isReadMode
              ? AppStrings.nfcStartScanning
              : AppStrings.nfcStartWriting);

    return Column(
      key: const ValueKey('nfc-setup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spaceL),
        _buildModeSegmentedControl(),
        if (isSimulationMode) ...[
          const SizedBox(height: AppDimensions.spaceM),
          const NfcStatusBanner(
            message:
                'NFC hardware not available. You can still test the full flow in simulation mode.',
            isAttention: true,
          ),
        ],
        if (_operationErrorMessage != null) ...[
          const SizedBox(height: AppDimensions.spaceM),
          NfcStatusBanner(message: _operationErrorMessage!, isAttention: true),
        ],
        const SizedBox(height: AppDimensions.spaceXXL),
        if (!isReadMode) ...[
          if (_isLoadingPets)
            const Center(child: CircularProgressIndicator())
          else if (_petsLoadErrorMessage != null) ...[
            NfcStatusBanner(message: _petsLoadErrorMessage!, isAttention: true),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _loadPets,
                child: const Text(AppStrings.petsRetry),
              ),
            ),
          ] else if (_pets.isEmpty)
            const NfcStatusBanner(
              message:
                  'You do not have pets yet. Add one before writing an NFC tag.',
              isAttention: true,
            )
          else ...[
            Text(
              AppStrings.nfcSelectPetToLink,
              style: TextStyle(
                color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            _buildPetPhotoSelector(),
          ],
          const SizedBox(height: AppDimensions.spaceXL),
        ],
        Center(child: NfcHeaderGraphic(state: NfcHeaderGraphicState.idle)),
        const SizedBox(height: AppDimensions.spaceL),
        Center(
          child: Text(
            isReadMode
                ? AppStrings.nfcScanTitle
                : 'Write Tag for $selectedPetName',
            style: TextStyle(
              color: isDark
                  ? AppColors.onBackgroundDark
                  : AppColors.onBackground,
              fontSize: AppDimensions.iconM,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Center(
          child: Text(
            isReadMode
                ? AppStrings.nfcScanDescription
                : "Hold your phone near a blank NFC tag to write $selectedPetName's emergency info",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (!isReadMode && canWriteTag) ...[
          const SizedBox(height: AppDimensions.spaceL),
          Text(
            AppStrings.nfcDataToWrite,
            style: TextStyle(
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          const NfcDataToggle(
            title: AppStrings.nfcBasicInfoOption,
            value: true,
            enabled: false,
          ),
          NfcDataToggle(
            title: AppStrings.nfcOwnerContactOption,
            value: _includeOwnerContact,
            onChanged: (newValue) {
              setState(() {
                _includeOwnerContact = newValue;
              });
            },
          ),
          NfcDataToggle(
            title: AppStrings.nfcEmergencyOption,
            value: _includeEmergencyInfo,
            onChanged: (newValue) {
              setState(() {
                _includeEmergencyInfo = newValue;
              });
            },
          ),
        ],
        const SizedBox(height: AppDimensions.spaceL),
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightL,
          child: FilledButton(
            onPressed: canStartNfc ? _startScanning : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
            ),
            child: Text(
              actionButtonText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (isReadMode) ...[
          const SizedBox(height: AppDimensions.spaceL),
          _buildReadingInfoCard(),
        ],
      ],
    );
  }

  Widget _buildPetPhotoSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTextColor = AppColors.primary;
    final unselectedTextColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.onSurface;
    final cardBackground = isDark
        ? AppColors.quickActionIconBackgroundDark
        : AppColors.primaryVariant;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spaceM),
        itemBuilder: (context, index) {
          final item = _pets[index];
          final isSelected = item.id == _selectedPetId;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPetId = item.id;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : (isDark
                              ? Border.all(color: AppColors.grey700)
                              : null),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? selectedTextColor
                          : unselectedTextColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  item.name,
                  style: TextStyle(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanningContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWriteMode = _mode == _NfcMode.write;

    return Column(
      key: const ValueKey('nfc-scanning'),
      children: [
        SizedBox(
          height: isWriteMode
              ? AppDimensions.iconXXXL + AppDimensions.spaceXXL
              : AppDimensions.iconXXXL,
        ),
        Center(child: NfcHeaderGraphic(state: NfcHeaderGraphicState.scanning)),
        const SizedBox(height: AppDimensions.spaceXL),
        Text(
          isWriteMode ? AppStrings.nfcWriting : AppStrings.nfcScanning,
          style: TextStyle(
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackground,
            fontSize: AppDimensions.iconL - AppDimensions.spaceS,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          AppStrings.nfcScanningHint,
          style: TextStyle(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScanningDot(color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: AppDimensions.spaceS),
            _buildScanningDot(color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: AppDimensions.spaceS),
            _buildScanningDot(color: AppColors.primary.withValues(alpha: 0.8)),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceM),
        TextButton(
          onPressed: _cancelScanning,
          child: Text(
            AppStrings.nfcCancel,
            style: TextStyle(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pet = _selectedPet;
    if (_mode == _NfcMode.write && pet != null) {
      return _buildWriteSuccessContent(pet);
    }

    return Column(
      key: const ValueKey('nfc-success'),
      children: [
        const SizedBox(height: AppDimensions.spaceXL),
        Center(child: NfcHeaderGraphic(state: NfcHeaderGraphicState.success)),
        const SizedBox(height: AppDimensions.spaceL),
        const Text(
          AppStrings.nfcScanSuccess,
          style: TextStyle(
            color: AppColors.success,
            fontSize: AppDimensions.iconM - AppDimensions.spaceS,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        _buildScannedTagCard(pet),
        if (_lastReadRawPayload != null && _lastReadTagData == null) ...[
          const SizedBox(height: AppDimensions.spaceM),
          NfcStatusBanner(message: 'Tag data: ${_lastReadRawPayload!}'),
        ],
        const SizedBox(height: AppDimensions.spaceL),
        TextButton(
          onPressed: _scanAnotherTag,
          child: Text(
            AppStrings.nfcScanAnotherTag,
            style: TextStyle(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWriteSuccessContent(PetUiModel pet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payload = _lastWrittenTagData ?? const <String, dynamic>{};
    final ownerName = _readPayloadOptionalText(payload, const [
      'ownerName',
      'owner_name',
      'owner.name',
      'contact.ownerName',
      'contact.owner_name',
    ]);
    final ownerPhone = _readPayloadOptionalText(payload, const [
      'ownerPhone',
      'owner_phone',
      'owner.phone',
      'contact.ownerPhone',
      'contact.owner_phone',
    ]);

    return Column(
      key: const ValueKey('nfc-write-success'),
      children: [
        const SizedBox(height: AppDimensions.iconXXXL),
        Container(
          width: AppDimensions.iconXXXL + AppDimensions.spaceL,
          height: AppDimensions.iconXXXL + AppDimensions.spaceL,
          decoration: BoxDecoration(
            color:
                (isDark
                        ? AppColors.positiveBackgroundDark
                        : AppColors.petStatusHealthyBg)
                    .withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: AppDimensions.iconXXL,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Text(
          AppStrings.nfcTagWrittenTitle,
          style: TextStyle(
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackground,
            fontSize: AppDimensions.iconM,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Text(
          '${pet.name}${AppStrings.nfcTagWrittenDescriptionSuffix}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            AppDimensions.spaceL - AppDimensions.spaceXS,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.quickActionIconBackgroundDark
                : AppColors.primaryVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: isDark ? Border.all(color: AppColors.grey700) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.nfcStoredOnTagTitle,
                style: TextStyle(
                  color: isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              _buildStoredTagItem(
                '${AppStrings.nfcStoredPetLabel}: ${pet.name} (${pet.breed})',
              ),
              if (ownerName != null)
                _buildStoredTagItem(
                  '${AppStrings.nfcStoredOwnerLabel}: $ownerName',
                ),
              if (ownerPhone != null)
                _buildStoredTagItem(
                  '${AppStrings.nfcStoredPhoneLabel}: $ownerPhone',
                ),
              _buildStoredTagItem(
                '${AppStrings.nfcStoredMicrochipLabel}: ${AppStrings.nfcStoredMicrochipValue}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppDimensions.buttonHeightL,
                child: OutlinedButton(
                  onPressed: _writeAnotherTag,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: AppDimensions.strokeRegular,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCircle,
                      ),
                    ),
                  ),
                  child: const Text(
                    AppStrings.nfcWriteAnother,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: SizedBox(
                height: AppDimensions.buttonHeightL,
                child: FilledButton(
                  onPressed: _finishWriting,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCircle,
                      ),
                    ),
                  ),
                  child: const Text(
                    AppStrings.nfcDone,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoredTagItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            color: AppColors.primary,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? AppColors.onSurfaceDark
                    : AppColors.onBackground,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentedControl() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          width: double.infinity,
          height: 45,
          padding: const EdgeInsets.all(AppDimensions.spaceXXS),
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryDark : AppColors.grey300,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            border: isDark ? Border.all(color: AppColors.grey700) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeSegmentButton(
                  label: AppStrings.nfcReadTag,
                  isSelected: _mode == _NfcMode.read,
                  onTap: () => _setMode(_NfcMode.read),
                ),
              ),
              Expanded(
                child: _ModeSegmentButton(
                  label: AppStrings.nfcWriteTag,
                  isSelected: _mode == _NfcMode.write,
                  onTap: () => _setMode(_NfcMode.write),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final benefits = [
      AppStrings.nfcReadingBenefitOne,
      AppStrings.nfcReadingBenefitTwo,
      AppStrings.nfcReadingBenefitThree,
      AppStrings.nfcReadingBenefitFour,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isDark ? Border.all(color: AppColors.grey700) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.nfcWhatDoesReadingDo,
            style: TextStyle(
              color: isDark
                  ? AppColors.onBackgroundDark
                  : AppColors.onBackground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannedTagCard(PetUiModel? pet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarSize = AppDimensions.iconXL - AppDimensions.spaceXS;
    const headerHeight = 96.0;
    final payload = _lastReadTagData;
    final displayName = _readPayloadText(payload, const [
      'petName',
      'name',
      'pet_name',
      'pet.name',
    ], fallback: pet?.name ?? AppStrings.valueNotAvailable);
    final displayBreed = _readPayloadText(payload, const [
      'breed',
      'pet_breed',
      'pet.breed',
    ], fallback: pet?.breed ?? AppStrings.valueNotAvailable);
    final displaySpecies = _readPayloadText(payload, const [
      'species',
      'pet_species',
      'pet.species',
    ], fallback: pet?.species ?? AppStrings.valueNotAvailable);
    final ownerName = _readPayloadText(payload, const [
      'ownerName',
      'owner_name',
      'owner.name',
      'contact.ownerName',
      'contact.owner_name',
    ], fallback: AppStrings.valueNotAvailable);
    final ownerPhone = _readPayloadText(payload, const [
      'ownerPhone',
      'owner_phone',
      'owner.phone',
      'contact.ownerPhone',
      'contact.owner_phone',
    ], fallback: AppStrings.valueNotAvailable);
    final medicalNotesValue = _buildMedicalNotes(payload);
    final statusKey = _resolvePetStatus(payload, pet);
    final statusLabel = _statusLabel(statusKey);
    final statusIcon = _statusIcon(statusKey);
    final statusBadgeBackground = _statusBadgeBackground(statusKey);
    final statusBadgeTextColor = _statusBadgeTextColor(statusKey);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.shadowSoft,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark ? Border.all(color: AppColors.grey700) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXL),
              topRight: Radius.circular(AppDimensions.radiusXL),
            ),
            child: Container(
              width: double.infinity,
              height: headerHeight,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: AppDimensions.spaceS,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppDimensions.iconL + AppDimensions.spaceS,
                    height: AppDimensions.iconL + AppDimensions.spaceS,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppColors.onPrimary,
                      size: AppDimensions.iconM,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          '$displayBreed - $displaySpecies',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceS,
                      vertical: AppDimensions.spaceXXS,
                    ),
                    decoration: BoxDecoration(
                      color: statusBadgeBackground,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusCircle,
                      ),
                      border: Border.all(
                        color: statusBadgeTextColor.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: statusBadgeTextColor,
                          size: AppDimensions.iconS,
                        ),
                        const SizedBox(width: AppDimensions.spaceXXS),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusBadgeTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nfcOwnerInformation,
                  style: TextStyle(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryVariant,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _ownerInitials(ownerName),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.onBackgroundDark
                                  : AppColors.onBackground,
                              fontSize: AppDimensions.spaceM,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXXS),
                          Text(
                            ownerPhone,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.onSurfaceDark
                                  : AppColors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.negativeBackgroundDark
                        : AppColors.petStatusAttentionBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: isDark
                          ? AppColors.negativeTextDark
                          : AppColors.warning,
                      width: AppDimensions.strokeRegular,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: isDark
                                ? AppColors.negativeTextDark
                                : AppColors.warning,
                            size: AppDimensions.iconS,
                          ),
                          SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            AppStrings.nfcMedicalNotes,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.negativeTextDark
                                  : AppColors.warning,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        medicalNotesValue,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.warning,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolvePetStatus(Map<String, dynamic>? payload, PetUiModel? pet) {
    final payloadStatus = _readPayloadOptionalText(payload, const [
      'status',
      'petStatus',
      'pet_status',
      'pet.status',
    ]);

    final rawStatus = (payloadStatus ?? pet?.status ?? 'healthy')
        .trim()
        .toLowerCase();

    if (rawStatus.contains('lost')) {
      return 'lost';
    }

    if (rawStatus.contains('attention') ||
        rawStatus.contains('need') ||
        rawStatus.contains('overdue') ||
        rawStatus.contains('warning')) {
      return 'needs_attention';
    }

    return 'healthy';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'lost' => AppStrings.petDetailStatusLost,
      'needs_attention' => AppStrings.petDetailStatusNeedsAttention,
      _ => AppStrings.petDetailStatusHealthy,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'lost' => Icons.report_problem_rounded,
      'needs_attention' => Icons.warning_amber_rounded,
      _ => Icons.check_rounded,
    };
  }

  Color _statusBadgeBackground(String status) {
    return switch (status) {
      'lost' => AppColors.petStatusLostBg.withValues(alpha: 0.92),
      'needs_attention' => AppColors.petStatusAttentionBg.withValues(
        alpha: 0.92,
      ),
      _ => AppColors.petStatusHealthyBg.withValues(alpha: 0.92),
    };
  }

  Color _statusBadgeTextColor(String status) {
    return switch (status) {
      'lost' => AppColors.petStatusLostText,
      'needs_attention' => AppColors.petStatusAttentionText,
      _ => AppColors.petStatusHealthyText,
    };
  }

  String _buildMedicalNotes(Map<String, dynamic>? payload) {
    if (payload == null) {
      return AppStrings.nfcMedicalNotesValue;
    }

    final parts = <String>[];
    final allergies = _readPayloadOptionalText(payload, const [
      'knownAllergies',
      'known_allergies',
      'medical_notes',
      'emergency.knownAllergies',
      'emergency.known_allergies',
    ]);
    final vet = _readPayloadOptionalText(payload, const [
      'defaultVet',
      'default_vet',
      'emergency.defaultVet',
      'emergency.default_vet',
    ]);
    final clinic = _readPayloadOptionalText(payload, const [
      'defaultClinic',
      'default_clinic',
      'emergency.defaultClinic',
      'emergency.default_clinic',
    ]);

    if (allergies != null && allergies.isNotEmpty) {
      parts.add('Allergies: $allergies');
    }
    if (vet != null && vet.isNotEmpty) {
      parts.add('Vet: $vet');
    }
    if (clinic != null && clinic.isNotEmpty) {
      parts.add('Clinic: $clinic');
    }

    if (parts.isEmpty) {
      return AppStrings.nfcMedicalNotesValue;
    }

    return parts.join('. ');
  }

  Widget _buildScanningDot({required Color color}) {
    return Container(
      width: AppDimensions.spaceS,
      height: AppDimensions.spaceS,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _ownerInitials(String fullName) {
    final normalizedName = fullName.trim();
    if (normalizedName.isEmpty) {
      return '?';
    }

    final parts = normalizedName.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return normalizedName.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}

class _NfcTopBar extends StatelessWidget {
  const _NfcTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
        vertical: AppDimensions.spaceS,
      ),
      child: SizedBox(
        height: AppDimensions.appBarHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                AppStrings.nfcTitle,
                style: TextStyle(
                  color: isDark
                      ? AppColors.onBackgroundDark
                      : AppColors.onBackground,
                  fontSize: AppDimensions.spaceL - AppDimensions.spaceXS,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: isDark ? AppColors.secondaryDark : AppColors.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark
                        ? AppColors.onBackgroundDark
                        : AppColors.onBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  const _ModeSegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.backgroundDark : AppColors.surface)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.18)
                        : AppColors.shadowSoft,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
