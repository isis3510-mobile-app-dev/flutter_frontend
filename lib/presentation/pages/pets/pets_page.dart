import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import 'models/pet_ui_model.dart';
import 'services/pets_api_service.dart';
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
  final _service = PetsApiService();

  List<PetUiModel> _allPets = [];
  List<PetUiModel> _filtered = [];
  bool _loading = true;
  String? _errorMessage;
  PetFilter _activeFilter = PetFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final pets = await _service.fetchPets();
      if (!mounted) return;

      setState(() {
        _allPets = pets;
        _filtered = _applyFilters(pets, _activeFilter, _searchQuery);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load pets right now.';
      });
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
    } else if (filter == PetFilter.vaccineDue) {
      result = result.where((p) => p.status == 'needs attention').toList();
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
              showCount: !_loading,
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
        onAddPet: () => Navigator.pushNamed(context, Routes.addPet),
        onAddVaccine: () {},
        onAddEvent: () {},
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          // TODO: navigate to the corresponding tab
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadPets);
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
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceM),
      itemBuilder: (_, index) {
        final pet = _filtered[index];
        return PetCard(
          pet: pet,
          onTap: () {
            // TODO: Navigator.pushNamed(context, Routes.petDetail, arguments: pet.id)
          },
          onVaccinesTap: () {},
          onLostModeTap: () {},
          onNfcTap: () {},
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
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: SingleChildScrollView(
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
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              FilledButton(
                onPressed: onRetry,
                child: const Text(AppStrings.petsRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
