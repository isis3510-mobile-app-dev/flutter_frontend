import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/nfc_service.dart';
import '../../../core/services/pet_service.dart';
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
  static const _defaultOwnerName = 'Sarah Johnson';
  static const _defaultOwnerPhone = '+1 (555) 012-3456';

  final NfcService _nfcService = NfcService();
  final PetService _petService = PetService();

  List<PetUiModel> _pets = const [];
  String? _selectedPetId;

  bool _isLoadingPets = false;
  String? _petsLoadErrorMessage;

  _NfcMode _mode = _NfcMode.read;
  _NfcViewState _viewState = _NfcViewState.setup;

  bool _includeOwnerContact = true;
  bool _includeEmergencyInfo = true;

  String? _operationErrorMessage;
  String? _lastReadRawPayload;
  Map<String, dynamic>? _lastReadTagData;
  Map<String, dynamic>? _lastWrittenTagData;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoadingPets = true;
      _petsLoadErrorMessage = null;
    });

    try {
      final pets = await _petService.getPets();
      final mappedPets = pets.map((pet) => pet.toUiModel()).toList(growable: false);

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
    });
  }

  Future<void> _startScanning() async {
    setState(() {
      _viewState = _NfcViewState.scanning;
      _operationErrorMessage = null;
    });

    try {
      if (_mode == _NfcMode.read) {
        final payload = await _nfcService.readTextTag();
        final parsedPayload = _tryParseJsonMap(payload);
        final scannedPetId = parsedPayload?['petId']?.toString();

        if (!mounted) {
          return;
        }

        setState(() {
          _lastReadRawPayload = payload;
          _lastReadTagData = parsedPayload;
          if (scannedPetId != null && _pets.any((pet) => pet.id == scannedPetId)) {
            _selectedPetId = scannedPetId;
          }
          _viewState = _NfcViewState.success;
        });
        return;
      }

      final selectedPet = _selectedPet;
      if (selectedPet == null) {
        _handleNfcError('You do not have pets available to write. Add a pet first.');
        return;
      }

      final payloadData = _buildWritePayload(selectedPet);
      await _nfcService.writeTextTag(jsonEncode(payloadData));

      if (!mounted) {
        return;
      }

      setState(() {
        _lastWrittenTagData = payloadData;
        _viewState = _NfcViewState.success;
      });
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

  Future<void> _cancelScanning() async {
    await _nfcService.stopSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
    });
  }

  void _scanAnotherTag() {
    setState(() {
      _mode = _NfcMode.read;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
    });
  }

  void _writeAnotherTag() {
    setState(() {
      _mode = _NfcMode.write;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
    });
  }

  void _finishWriting() {
    setState(() {
      _mode = _NfcMode.read;
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = null;
    });
  }

  void _handleNfcError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _viewState = _NfcViewState.setup;
      _operationErrorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, dynamic> _buildWritePayload(PetUiModel pet) {
    final payload = <String, dynamic>{
      'app': 'PetCare',
      'version': 1,
      'petId': pet.id,
      'name': pet.name,
      'species': pet.species,
      'breed': pet.breed,
    };

    if (_includeOwnerContact) {
      payload['ownerName'] = _defaultOwnerName;
      payload['ownerPhone'] = _defaultOwnerPhone;
    }

    if (_includeEmergencyInfo) {
      payload['knownAllergies'] = pet.knownAllergies;
      payload['defaultVet'] = pet.defaultVet;
      payload['defaultClinic'] = pet.defaultClinic;
    }

    return payload;
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
    final isReadMode = _mode == _NfcMode.read;
    final pet = _selectedPet;
    final selectedPetName = pet?.name ?? 'your pet';
    final canWriteTag = pet != null;
    final canStartNfc = isReadMode || canWriteTag;

    return Column(
      key: const ValueKey('nfc-setup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spaceL),
        _buildModeSegmentedControl(),
        if (_operationErrorMessage != null) ...[
          const SizedBox(height: AppDimensions.spaceM),
          NfcStatusBanner(
            message: _operationErrorMessage!,
            isAttention: true,
          ),
        ],
        const SizedBox(height: AppDimensions.spaceXXL),
        if (!isReadMode) ...[
          if (_isLoadingPets)
            const Center(child: CircularProgressIndicator())
          else if (_petsLoadErrorMessage != null) ...[
            NfcStatusBanner(
              message: _petsLoadErrorMessage!,
              isAttention: true,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _loadPets,
                child: const Text(AppStrings.petsRetry),
              ),
            ),
          ] else if (_pets.isEmpty)
            const NfcStatusBanner(
              message: 'You do not have pets yet. Add one before writing an NFC tag.',
              isAttention: true,
            )
          else ...[
            const Text(
              AppStrings.nfcSelectPetToLink,
              style: TextStyle(
                color: AppColors.grey700,
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
            isReadMode ? AppStrings.nfcScanTitle : 'Write Tag for $selectedPetName',
            style: const TextStyle(
              color: AppColors.onBackground,
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
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (!isReadMode && canWriteTag) ...[
          const SizedBox(height: AppDimensions.spaceL),
          const Text(
            AppStrings.nfcDataToWrite,
            style: TextStyle(
              color: AppColors.grey700,
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
              isReadMode ? AppStrings.nfcStartScanning : AppStrings.nfcStartWriting,
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
                    color: AppColors.primaryVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  item.name,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
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
            color: AppColors.onBackground,
            fontSize: AppDimensions.iconL - AppDimensions.spaceS,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        const Text(
          AppStrings.nfcScanningHint,
          style: TextStyle(
            color: AppColors.onSurface,
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
          child: const Text(
            AppStrings.nfcCancel,
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
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
          child: const Text(
            AppStrings.nfcScanAnotherTag,
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWriteSuccessContent(PetUiModel pet) {
    final payload = _lastWrittenTagData ?? _buildWritePayload(pet);
    final ownerName = payload['ownerName']?.toString();
    final ownerPhone = payload['ownerPhone']?.toString();

    return Column(
      key: const ValueKey('nfc-write-success'),
      children: [
        const SizedBox(height: AppDimensions.iconXXXL),
        Container(
          width: AppDimensions.iconXXXL + AppDimensions.spaceL,
          height: AppDimensions.iconXXXL + AppDimensions.spaceL,
          decoration: BoxDecoration(
            color: AppColors.petStatusHealthyBg.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: AppDimensions.iconXXL,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        const Text(
          AppStrings.nfcTagWrittenTitle,
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: AppDimensions.iconM,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Text(
          '${pet.name}${AppStrings.nfcTagWrittenDescriptionSuffix}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spaceL - AppDimensions.spaceXS),
          decoration: BoxDecoration(
            color: AppColors.primaryVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.nfcStoredOnTagTitle,
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              _buildStoredTagItem('${AppStrings.nfcStoredPetLabel}: ${pet.name} (${pet.breed})'),
              if (ownerName != null)
                _buildStoredTagItem('${AppStrings.nfcStoredOwnerLabel}: $ownerName'),
              if (ownerPhone != null)
                _buildStoredTagItem('${AppStrings.nfcStoredPhoneLabel}: $ownerPhone'),
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
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
              style: const TextStyle(
                color: AppColors.onBackground,
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          width: double.infinity,
          height: 45,
          padding: const EdgeInsets.all(AppDimensions.spaceXXS),
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.nfcWhatDoesReadingDo,
            style: TextStyle(
              color: AppColors.onBackground,
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
                      style: const TextStyle(
                        color: AppColors.onSurface,
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
    final avatarSize = AppDimensions.iconXL - AppDimensions.spaceXS;
    final imageHeight = AppDimensions.iconXXXL + AppDimensions.spaceXXXL;
    final payload = _lastReadTagData;
    final displayName = payload?['name']?.toString() ?? pet?.name ?? AppStrings.valueNotAvailable;
    final displayBreed = payload?['breed']?.toString() ?? pet?.breed ?? AppStrings.valueNotAvailable;
    final displaySpecies = payload?['species']?.toString() ?? pet?.species ?? AppStrings.valueNotAvailable;
    final ownerName = payload?['ownerName']?.toString() ?? _defaultOwnerName;
    final ownerPhone = payload?['ownerPhone']?.toString() ?? _defaultOwnerPhone;
    final medicalNotesValue = _buildMedicalNotes(payload);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXL),
              topRight: Radius.circular(AppDimensions.radiusXL),
            ),
            child: SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AppAssets.imageDogPrimary,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppDimensions.spaceM,
                    right: AppDimensions.spaceM,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceS,
                        vertical: AppDimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.petStatusHealthyBg,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: AppColors.petStatusHealthyText,
                            size: AppDimensions.iconS,
                          ),
                          SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            AppStrings.nfcHealthyStatus,
                            style: TextStyle(
                              color: AppColors.petStatusHealthyText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppDimensions.spaceM,
                    bottom: AppDimensions.spaceM,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: AppDimensions.iconL - AppDimensions.spaceXXS,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          '$displayBreed - $displaySpecies',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
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
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.nfcOwnerInformation,
                  style: TextStyle(
                    color: AppColors.grey700,
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
                            style: const TextStyle(
                              color: AppColors.onBackground,
                              fontSize: AppDimensions.spaceM,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXXS),
                          Text(
                            ownerPhone,
                            style: const TextStyle(
                              color: AppColors.onSurface,
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
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightL,
                  child: FilledButton.icon(
                    onPressed: _showUnavailableMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                      ),
                    ),
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text(
                      AppStrings.nfcCallOwnerNow,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showUnavailableMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.nfcSmsActionBg,
                          foregroundColor: AppColors.nfcSmsActionFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                          ),
                        ),
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text(
                          AppStrings.nfcSendSms,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showUnavailableMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.petStatusAttentionBg,
                          foregroundColor: AppColors.warning,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                          ),
                        ),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text(
                          AppStrings.nfcShare,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.petStatusAttentionBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: AppColors.warning,
                      width: AppDimensions.strokeRegular,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: AppDimensions.iconS,
                          ),
                          SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            AppStrings.nfcMedicalNotes,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        medicalNotesValue,
                        style: const TextStyle(
                          color: AppColors.warning,
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

  String _buildMedicalNotes(Map<String, dynamic>? payload) {
    if (payload == null) {
      return AppStrings.nfcMedicalNotesValue;
    }

    final parts = <String>[];
    final allergies = payload['knownAllergies']?.toString();
    final vet = payload['defaultVet']?.toString();
    final clinic = payload['defaultClinic']?.toString();

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
            const Center(
              child: Text(
                AppStrings.nfcTitle,
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: AppDimensions.spaceL - AppDimensions.spaceXS,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.onBackground,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
