import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/models/smart_alert_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/smart_feature_service.dart';
import '../../../shared/widgets/smart_alert_card.dart';

class SmartAlertsPage extends StatefulWidget {
  const SmartAlertsPage({super.key, this.initialPetId});

  final String? initialPetId;

  @override
  State<SmartAlertsPage> createState() => _SmartAlertsPageState();
}

class _SmartAlertsPageState extends State<SmartAlertsPage> {
  final PetService _petService = PetService();
  final SmartFeatureService _smartFeatureService = SmartFeatureService();

  List<PetModel> _pets = const [];
  List<SmartAlertItem> _alerts = const [];
  String? _selectedPetId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPetId = _normalizePetId(widget.initialPetId);
    _loadAlerts();
  }

  String? _normalizePetId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pets = await _petService.getPets();

      final alertGroups = await Future.wait(
        pets.map((pet) async {
          try {
            final response = await _smartFeatureService.getPetSmartSuggestions(
              pet.id,
            );
            final displayPetName = pet.name.trim().isNotEmpty
                ? pet.name.trim()
                : response.petName.trim().isNotEmpty
                ? response.petName.trim()
                : AppStrings.valueNotAvailable;

            return response.suggestions
                .map(
                  (suggestion) => SmartAlertItem(
                    petId: pet.id,
                    petName: displayPetName,
                    suggestion: suggestion,
                  ),
                )
                .toList(growable: false);
          } catch (_) {
            return const <SmartAlertItem>[];
          }
        }),
      );

      if (!mounted) {
        return;
      }

      final alerts = alertGroups
          .expand((group) => group)
          .toList(growable: false);
      final availablePetIds = pets.map((pet) => pet.id).toSet();
      final normalizedSelection = _selectedPetId;

      setState(() {
        _pets = pets;
        _alerts = alerts;
        _selectedPetId =
            normalizedSelection != null &&
                availablePetIds.contains(normalizedSelection)
            ? normalizedSelection
            : null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppStrings.errorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SmartAlertItem> get _visibleAlerts {
    final selectedPetId = _selectedPetId;
    if (selectedPetId == null) {
      return _alerts;
    }
    return _alerts
        .where((item) => item.petId == selectedPetId)
        .toList(growable: false);
  }

  int _countForPet(String petId) {
    return _alerts.where((item) => item.petId == petId).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.smartAlertsPageTitle),
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const SizedBox(height: AppDimensions.spaceS),
          _buildInternetNotice(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 56,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grey700),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    OutlinedButton(
                      onPressed: _loadAlerts,
                      child: const Text(AppStrings.petsRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceS),
        _buildInternetNotice(),
        const SizedBox(height: AppDimensions.spaceM),
        _buildFilterBar(),
        const SizedBox(height: AppDimensions.spaceM),
        Expanded(
          child: _visibleAlerts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      top: AppDimensions.spaceS,
                      bottom: AppDimensions.spaceXXL,
                    ),
                    itemCount: _visibleAlerts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spaceS),
                    itemBuilder: (context, index) {
                      final alert = _visibleAlerts[index];
                      return SmartAlertCard(
                        suggestion: alert.suggestion,
                        petName: alert.petName,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.pageHorizontalPadding,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInternetNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppColors.smartAlertInfoBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.smartAlertInfoText,
            size: 20,
          ),
          SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              AppStrings.smartAlertsInternetNotice,
              style: TextStyle(
                color: AppColors.smartAlertInfoText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final petOptions = _pets
        .where((pet) {
          final count = _countForPet(pet.id);
          return count > 0 || _selectedPetId == pet.id;
        })
        .toList(growable: false);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        child: Row(
          children: [
            _AlertFilterChip(
              label: AppStrings.smartAlertsFilterAll,
              isSelected: _selectedPetId == null,
              onTap: () => setState(() => _selectedPetId = null),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            for (final pet in petOptions) ...[
              _AlertFilterChip(
                label:
                    '${pet.name.trim().isEmpty ? AppStrings.valueNotAvailable : pet.name.trim()} (${_countForPet(pet.id)})',
                isSelected: _selectedPetId == pet.id,
                onTap: () => setState(() => _selectedPetId = pet.id),
              ),
              const SizedBox(width: AppDimensions.spaceS),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pageHorizontalPadding,
        ),
        child: Text(
          AppStrings.smartAlertsEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.grey700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AlertFilterChip extends StatelessWidget {
  const _AlertFilterChip({
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

    final foregroundColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.grey500 : AppColors.grey700);
    final backgroundColor = isSelected
        ? AppColors.bottomNavActive
        : (isDark ? AppColors.secondaryDark : AppColors.secondary);
    final borderColor = isSelected
        ? AppColors.bottomNavActive
        : (isDark ? AppColors.grey700 : AppColors.grey300);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
