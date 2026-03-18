import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/profile_photo_service.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import 'models/pet_ui_mapper.dart';
import 'models/pet_ui_model.dart';
import 'pet_detail/pet_detail_args.dart';
import 'widgets/pet_card.dart';
import 'widgets/pet_count_pill.dart';
import 'widgets/pet_filter_chips.dart';
import 'widgets/pets_search_bar.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final PetService _petService = PetService();
  final ProfilePhotoService _photoService = ProfilePhotoService();

  List<PetUiModel> _allPets = const [];
  List<PetUiModel> _filtered = [];
  PetFilter _activeFilter = PetFilter.all;
  String _searchQuery = '';
  bool _isLoadingPets = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoadingPets = true;
      _loadErrorMessage = null;
    });

    try {
      final pets = await _petService.getPets();
      final mappedPetsRaw = pets
          .map((pet) => pet.toUiModel())
          .toList(growable: false);
      final mappedPets = await Future.wait(
        mappedPetsRaw.map((pet) async {
          final localPath = await _photoService.getPetPhotoPath(pet.id);
          return pet.copyWith(localPhotoPath: localPath);
        }),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allPets = mappedPets;
        _filtered = _applyFilters(mappedPets, _activeFilter, _searchQuery);
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadErrorMessage = AppStrings.petsLoadError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPets = false);
      }
    }
  }

  void _onFilterChanged(PetFilter filter) => setState(() {
    _activeFilter = filter;
    _filtered = _applyFilters(_allPets, filter, _searchQuery);
  });

  void _onSearchChanged(String query) => setState(() {
    _searchQuery = query;
    _filtered = _applyFilters(_allPets, _activeFilter, query);
  });

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section is not available yet.')),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 1) {
      return;
    }

    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      _showUnavailableMessage();
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  void _goToAddVaccine() {
    Navigator.of(context).pushNamed(Routes.addVaccine);
  }

  Future<void> _goToAddPet() async {
    await Navigator.pushNamed(context, Routes.addPet);
    if (!mounted) {
      return;
    }
    _loadPets();
  }

  void _goToAddEvent() {
    Navigator.of(context).pushNamed(Routes.addEvent);
  }

  Future<void> _openPetDetail(
    PetUiModel pet, {
    int initialTabIndex = 0,
  }) async {
    final changed = await Navigator.pushNamed(
      context,
      Routes.petDetail,
      arguments: PetDetailArgs(
        pet: pet,
        initialTabIndex: initialTabIndex,
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    await _loadPets();
  }

  Future<bool> _confirmMarkAsLost(PetUiModel pet) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.petLostConfirmTitle),
          content: Text(
            '${AppStrings.petLostConfirmMessage} (${pet.name})',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.petLostConfirmCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.petLostConfirmAction),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _toggleLostMode(PetUiModel pet) async {
    final isLost = pet.status == 'lost';

    if (!isLost) {
      final confirmed = await _confirmMarkAsLost(pet);
      if (!confirmed) {
        return;
      }
    }

    try {
      if (isLost) {
        await _petService.markPetAsFound(pet.id);
      } else {
        await _petService.markPetAsLost(pet.id);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLost
                ? '${pet.name} ${AppStrings.petMarkedAsFoundMessage}'
                : '${pet.name} ${AppStrings.petMarkedAsLostMessage}',
          ),
        ),
      );
      await _loadPets();
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
        const SnackBar(content: Text(AppStrings.petsLoadError)),
      );
    }
  }

  Future<void> _handleNfcTap(PetUiModel pet) async {
    try {
      if (pet.isNfcSynced) {
        await _petService.updatePet(
          petId: pet.id,
          data: {'isNfcSynced': false},
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pet.name} NFC deactivated')),
        );
        await _loadPets();
        return;
      }

      final result = await Navigator.pushNamed(
        context,
        Routes.nfc,
        arguments: pet.id,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        await _loadPets();
      }
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
        const SnackBar(content: Text(AppStrings.petsLoadError)),
      );
    }
  }

  static List<PetUiModel> _applyFilters(
    List<PetUiModel> pets,
    PetFilter filter,
    String query,
  ) {
    var result = pets;

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.breed.toLowerCase().contains(q),
          )
          .toList();
    }

    if (filter == PetFilter.healthy) {
      result = result.where((p) => p.status == 'healthy').toList();
    } else if (filter == PetFilter.lost) {
      result = result.where((p) => p.status == 'lost').toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              petCount: _allPets.length,
              showCount: true,
              activeFilter: _activeFilter,
              onFilterChanged: _onFilterChanged,
              onSearchChanged: _onSearchChanged,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: _goToAddPet,
        onAddVaccine: _goToAddVaccine,
        onAddEvent: _goToAddEvent,
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingPets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadErrorMessage != null) {
      return _ErrorState(message: _loadErrorMessage!, onRetry: _loadPets);
    }

    if (_filtered.isEmpty) {
      return _EmptyState(filter: _activeFilter);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        0,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceXXL,
      ),
      itemCount: _filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceM),
      itemBuilder: (_, index) {
        final pet = _filtered[index];
        return PetCard(
          pet: pet,
          onTap: () => _openPetDetail(pet),
          onVaccinesTap: () => _openPetDetail(pet, initialTabIndex: 1),
          onLostModeTap: () => _toggleLostMode(pet),
          onNfcTap: () => _handleNfcTap(pet),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets local to this page
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.petCount,
    required this.showCount,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final int petCount;
  final bool showCount;
  final PetFilter activeFilter;
  final ValueChanged<PetFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.petsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (showCount) ...[PetCountPill(count: petCount)],
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          PetsSearchBar(onChanged: onSearchChanged),
          const SizedBox(height: AppDimensions.spaceM),
          PetFilterChips(selected: activeFilter, onSelected: onFilterChanged),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final PetFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 56, color: AppColors.grey300),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              filter == PetFilter.all
                  ? AppStrings.petsEmpty
                  : AppStrings.petsEmptyFiltered,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.petsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
