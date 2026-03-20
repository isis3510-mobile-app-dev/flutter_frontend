import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/models/pet_model.dart';
import '../../../../core/models/smart_alert_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/event_service.dart';
import '../../../../core/services/pet_service.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../../core/services/smart_feature_service.dart';
import '../../../../core/services/telemetry_service.dart';
import '../../../../shared/widgets/quick_actions_fab.dart';
import '../../add_event/add_event_args.dart';
import '../../records/detail/detail_page.dart';
import '../models/pet_ui_mapper.dart';
import '../models/pet_ui_model.dart';
import 'tabs/events_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/vaccines_tab.dart';

enum _PetAction { edit, delete }

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({
    super.key,
    required this.pet,
    this.initialTabIndex = 0,
  });

  final PetUiModel pet;
  final int initialTabIndex;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PetService _petService = PetService();
  final EventService _eventService = EventService();
  final SmartFeatureService _smartFeatureService = SmartFeatureService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final TelemetryService _telemetryService = TelemetryService();

  Future<void> _goToAddVaccine() async {
    final result = await Navigator.pushNamed(context, Routes.addVaccine);
    if (result == true) {
      await _loadPetDetail();
    }
  }

  Future<void> _goToAddEvent() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEvent,
      arguments: AddEventArgs(petId: _pet.id, petName: _pet.name),
    );
    if (result == true) {
      _hasMutatedPet = true;
      await _loadPetDetail();
    }
  }

  late PetUiModel _pet;
  PetModel? _petDetails;
  List<EventModel> _petEvents = const [];
  List<SmartSuggestionModel> _smartSuggestions = const [];
  bool _isLoading = false;
  bool _hasMutatedPet = false;
  String? _errorMessage;
  String? _eventsErrorMessage;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadPetDetail();
  }

  Future<void> _loadPetDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _eventsErrorMessage = null;
    });

    try {
      final detail = await _petService.getPetById(widget.pet.id);
      final localPath = await _photoService.getPetPhotoPath(widget.pet.id);
      final uiPet = detail.toUiModel().copyWith(localPhotoPath: localPath);
      List<EventModel> petEvents = const [];
      List<SmartSuggestionModel> smartSuggestions = const [];
      String? eventsErrorMessage;

      try {
        petEvents = await _eventService.getEventsByPet(widget.pet.id);
      } on ApiException catch (error) {
        eventsErrorMessage = error.message;
      } catch (_) {
        eventsErrorMessage = AppStrings.errorGeneric;
      }

      try {
        final smartResponse = await _smartFeatureService.getPetSmartSuggestions(
          widget.pet.id,
        );
        smartSuggestions = smartResponse.suggestions;
      } catch (_) {
        smartSuggestions = const [];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _petDetails = detail;
        _pet = uiPet;
        _petEvents = petEvents..sort((a, b) => b.date.compareTo(a.date));
        _smartSuggestions = smartSuggestions;
        _eventsErrorMessage = eventsErrorMessage;
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
        _errorMessage = AppStrings.petsLoadError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEventDetail(EventModel event) async {
    if (_petDetails == null) {
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DetailPage(type: 'event', event: event, pet: _petDetails),
      ),
    );

    if (result == true) {
      _hasMutatedPet = true;
      await _loadPetDetail();
    }
  }

  Future<void> _toggleLostMode() async {
    final isLost = _pet.status == 'lost';

    if (!isLost) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(AppStrings.petLostConfirmTitle),
            content: Text('${AppStrings.petLostConfirmMessage} (${_pet.name})'),
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

      if (confirmed != true) {
        return;
      }
    }

    try {
      if (isLost) {
        await _petService.markPetAsFound(_pet.id);
      } else {
        await _petService.markPetAsLost(_pet.id);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLost
                ? '${_pet.name} ${AppStrings.petMarkedAsFoundMessage}'
                : '${_pet.name} ${AppStrings.petMarkedAsLostMessage}',
          ),
        ),
      );

      _hasMutatedPet = true;
      await _loadPetDetail();
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
    }
  }

  Future<void> _toggleNfc() async {
    try {
      if (_pet.isNfcSynced) {
        await _petService.updatePet(
          petId: _pet.id,
          data: {'isNfcSynced': false},
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('NFC desactivated')));

        _hasMutatedPet = true;
        await _loadPetDetail();
      } else {
        final result = await Navigator.pushNamed(
          context,
          Routes.nfc,
          arguments: _pet.id,
        );

        if (!mounted) {
          return;
        }

        if (result != null) {
          await _loadPetDetail();
        }
      }
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
    }
  }

  void _goBack() {
    Navigator.pop(context, _hasMutatedPet ? true : null);
  }

  Future<void> _openEditPet() async {
    final wasUpdated = await Navigator.pushNamed(
      context,
      Routes.addPet,
      arguments: _pet,
    );

    if (wasUpdated == true) {
      _hasMutatedPet = true;
      await _loadPetDetail();
      await _telemetryService.logAddPetExecutionIfPending(
        endTime: DateTime.now(),
      );
    }
  }

  Future<void> _showPetActionsMenu() async {
    final action = await showModalBottomSheet<_PetAction>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text(AppStrings.petDetailMenuEdit),
                onTap: () => Navigator.pop(bottomSheetContext, _PetAction.edit),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  AppStrings.petDetailMenuDelete,
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () =>
                    Navigator.pop(bottomSheetContext, _PetAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _PetAction.edit) {
      await _openEditPet();
      return;
    }

    await _confirmAndDeletePet();
  }

  Future<void> _confirmAndDeletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.petDeleteConfirmTitle),
          content: Text('${AppStrings.petDeleteConfirmMessage} (${_pet.name})'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.petLostConfirmCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.petDeleteConfirmAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _petService.deletePet(_pet.id);
      await _photoService.clearPetPhotoPath(_pet.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.petDeletedMessage)),
      );
      Navigator.pop(context, true);
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
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.background,
        body: _buildBody(),
        floatingActionButton: QuickActionsFab(
          onAddPet: () {},
          onAddVaccine: () {},
          onAddEvent: () {},
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey700),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              OutlinedButton(
                onPressed: _loadPetDetail,
                child: const Text(AppStrings.petsRetry),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _PetDetailHeader(
          pet: _pet,
          onBack: _goBack,
          onEdit: _openEditPet,
          onMore: _showPetActionsMenu,
        ),
        _PetDetailTabBar(controller: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(
                pet: _pet,
                petDetails: _petDetails,
                eventCount: _petEvents.length,
                smartAlerts: _smartSuggestions,
                onToggleLostMode: _toggleLostMode,
                onToggleNfc: _toggleNfc,
              ),
              VaccinesTab(
                pet: _pet,
                vaccinations: _petDetails?.vaccinations ?? const [],
                onAddVaccine: _goToAddVaccine,
              ),
              EventsTab(
                pet: _pet,
                events: _petEvents,
                isLoading: false,
                errorMessage: _eventsErrorMessage,
                onAddEvent: _goToAddEvent,
                onRetry: _loadPetDetail,
                onOpenEvent: _openEventDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PetDetailHeader extends StatelessWidget {
  const _PetDetailHeader({
    required this.pet,
    required this.onBack,
    required this.onEdit,
    required this.onMore,
  });

  final PetUiModel pet;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.petDetailHeaderBg,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background circle
            Positioned(
              right: -30,
              top: -96,
              child: Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bottomNavActive.withValues(alpha: 0.45),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActionBar(onBack: onBack, onEdit: onEdit, onMore: onMore),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceXS,
                    AppDimensions.pageHorizontalPadding,
                    AppDimensions.spaceL,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PetPhoto(
                        photoUrl: pet.effectivePhotoPath,
                        species: pet.species,
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(child: _PetInfo(pet: pet)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onBack,
    required this.onEdit,
    required this.onMore,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            tooltip: AppStrings.semanticBackButton,
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
            tooltip: AppStrings.petDetailEditSemantics,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            tooltip: AppStrings.petDetailMoreSemantics,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.photoUrl, required this.species});

  final String? photoUrl;
  final String species;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildPhoto(),
    );
  }

  Widget _buildPhoto() {
    final value = photoUrl?.trim();
    if (value == null || value.isEmpty) {
      return _PhotoPlaceholder(species: species);
    }

    if (_isRemotePhoto(value)) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _PhotoPlaceholder(species: species),
      );
    }

    return Image.file(
      File(value),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _PhotoPlaceholder(species: species),
    );
  }

  bool _isRemotePhoto(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) {
    final assetName = species.toLowerCase() == 'cat'
        ? 'catSecondary'
        : 'dogSecondary';
    return ColoredBox(
      color: AppColors.bottomNavActive.withValues(alpha: 0.6),
      child: Center(
        child: Image.asset(
          'assets/images/$assetName.png',
          width: 46,
          height: 46,
          errorBuilder: (_, _, _) => SvgPicture.asset(
            'assets/icons/featureIcons/pets.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _PetInfo extends StatelessWidget {
  const _PetInfo({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatusBadge(status: pet.status),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${pet.breed} · ${pet.species}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        _PetMetaRow(pet: pet),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (status) {
      'healthy' => AppColors.petStatusHealthyBg,
      'lost' => AppColors.petStatusLostBg,
      _ => AppColors.petStatusAttentionBg,
    };
    final textColor = switch (status) {
      'healthy' => AppColors.petStatusHealthyText,
      'lost' => AppColors.petStatusLostText,
      _ => AppColors.petStatusAttentionText,
    };
    final label = switch (status) {
      'healthy' => AppStrings.petDetailStatusHealthy,
      'lost' => AppStrings.petDetailStatusLost,
      _ => AppStrings.petDetailStatusNeedsAttention,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _PetMetaRow extends StatelessWidget {
  const _PetMetaRow({required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final genderIcon = pet.gender.toLowerCase() == 'female'
        ? 'assets/icons/petRelated/female.svg'
        : 'assets/icons/petRelated/male.svg';

    return Row(
      children: [
        _MetaItem(
          iconPath: 'assets/icons/petRelated/age.svg',
          label: pet.ageLabel,
        ),
        const SizedBox(width: 14),
        _MetaItem(
          iconPath: 'assets/icons/petRelated/weight.svg',
          label: pet.weightLabel,
        ),
        const SizedBox(width: 14),
        _MetaItem(iconPath: genderIcon, label: pet.gender),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.iconPath, required this.label});

  final String iconPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.85),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Tab Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PetDetailTabBar extends StatelessWidget {
  const _PetDetailTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.petDetailInfoBackgroundDark : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Row(
              children: [
                _Tab(
                  label: AppStrings.petDetailTabOverview,
                  svgPath: 'assets/icons/featureIcons/overview.svg',
                  isActive: controller.index == 0,
                  isDark: isDark,
                  onTap: () => controller.animateTo(0),
                ),
                _Tab(
                  label: AppStrings.petDetailTabVaccines,
                  svgPath: 'assets/icons/featureIcons/vaccines.svg',
                  isActive: controller.index == 1,
                  isDark: isDark,
                  onTap: () => controller.animateTo(1),
                ),
                _Tab(
                  label: AppStrings.petDetailTabEvents,
                  svgPath: 'assets/icons/featureIcons/calendar.svg',
                  isActive: controller.index == 2,
                  isDark: isDark,
                  onTap: () => controller.animateTo(2),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? AppColors.bottomNavTopBorderDark
                : AppColors.petFilterInactiveBorder,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.svgPath,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String svgPath;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark
        ? AppColors.addPetPhotoBackground
        : AppColors.bottomNavActive;
    final inactiveColor = isDark
        ? AppColors.bottomNavInactiveDark
        : AppColors.bottomNavInactive;
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    svgPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2.5,
              color: isActive ? activeColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
