import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/profile_photo_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/vaccine_service.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import '../add_event/add_event_args.dart';
import '../add_vaccine/add_vaccine_args.dart';
import '../pets/models/pet_ui_mapper.dart';
import '../pets/models/pet_ui_model.dart';
import 'widgets/event_card.dart';
import 'widgets/home_header.dart';
import 'widgets/overdue_vaccines_card.dart';
import 'widgets/pet_card.dart';
import 'widgets/upcoming_vaccine_card.dart';

/// Home page of the application - main dashboard.
/// Shows a greeting, pet overview, upcoming events, and quick actions.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _currentIndex = 0;

  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final EventService _eventService = EventService();
  final VaccineService _vaccineService = VaccineService();
  final ProfilePhotoService _photoService = ProfilePhotoService();

  String _userName = '';
  List<PetUiModel> _pets = const [];
  List<_HomeEventEntry> _upcomingEvents = const [];
  _UpcomingVaccineData? _nextVaccine;
  _OverdueVaccineData? _overdueVaccineData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section is not available yet.')),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) {
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

  void _goToAddEvent() {
    Navigator.of(context).pushNamed(Routes.addEvent);
  }

  void _goToPetDetail(PetUiModel pet) {
    Navigator.of(context).pushNamed(Routes.petDetail, arguments: pet);
  }

  Future<void> _editEvent(_HomeEventEntry entry) async {
    final result = await Navigator.of(context).pushNamed(
      Routes.addEvent,
      arguments: AddEventArgs(
        eventId: entry.event.id,
        petId: entry.petId,
        petName: entry.petName,
        title: entry.event.title,
        description: entry.event.description,
        date: entry.event.date,
        eventType: entry.event.eventType,
        price: entry.event.price,
        provider: entry.event.provider,
        clinic: entry.event.clinic,
        followUpDate: entry.event.followUpDate,
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    await _loadHomeData();
  }

  Future<void> _editVaccine(_VaccinationWithPet entry, String vaccineName) async {
    final result = await Navigator.of(context).pushNamed(
      Routes.addVaccine,
      arguments: AddVaccineArgs(
        vaccinationId: entry.vaccination.id,
        vaccineId: entry.vaccination.vaccineId,
        vaccineName: vaccineName,
        dateGiven: entry.vaccination.dateGiven,
        petId: entry.petId,
        petName: entry.petName,
        administeredBy: entry.vaccination.administeredBy,
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    await _loadHomeData();
  }

  void _goToRecords(int initialFilterIndex) {
    Navigator.of(
      context,
    ).pushNamed(Routes.records, arguments: initialFilterIndex);
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _userService.getCurrentUser(),
        _petService.getPets(),
      ]);
      final profile = results[0];
      final pets = results[1] as List<PetModel>;

      final allVaccinations = <_VaccinationWithPet>[];
      for (final pet in pets) {
        allVaccinations.addAll(
          pet.vaccinations.map(
            (vaccination) => _VaccinationWithPet(
              petId: pet.id,
              petName: pet.name,
              vaccination: vaccination,
            ),
          ),
        );
      }

      final uiPets = await Future.wait(
        pets.map((pet) async {
          final localPath = await _photoService.getPetPhotoPath(pet.id);
          return pet.toUiModel().copyWith(localPhotoPath: localPath);
        }),
      );

      final eventGroups = await Future.wait(
        pets.map((pet) async {
          try {
            final petEvents = await _eventService.getEventsByPet(pet.id);
            return petEvents
                .map(
                  (event) => _HomeEventEntry(
                    event: event,
                    petId: pet.id,
                    petName: pet.name,
                  ),
                )
                .toList(growable: false);
          } catch (_) {
            return const <_HomeEventEntry>[];
          }
        }),
      );
      final events = eventGroups.expand((group) => group).toList(growable: false);

      final vaccineIds = allVaccinations
          .map((entry) => entry.vaccination.vaccineId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      final vaccineNameEntries = await Future.wait(
        vaccineIds.map((vaccineId) async {
          try {
            final vaccine = await _vaccineService.getVaccineById(vaccineId);
            final name = vaccine.name.trim();
            return MapEntry(vaccineId, name.isEmpty ? vaccineId : name);
          } catch (_) {
            return MapEntry(vaccineId, vaccineId);
          }
        }),
      );
      final vaccineNamesById = Map<String, String>.fromEntries(vaccineNameEntries);

      final now = DateTime.now();
      final overdueVaccines = allVaccinations.where((entry) {
        final due = entry.vaccination.nextDueDate;
        return due.year > 1 && due.isBefore(now);
      }).toList(growable: false)
        ..sort(
          (a, b) => a.vaccination.nextDueDate.compareTo(b.vaccination.nextDueDate),
        );

      final upcomingVaccines = allVaccinations.where((entry) {
        final due = entry.vaccination.nextDueDate;
        return due.year > 1 && due.isAfter(now);
      }).toList(growable: false)
        ..sort(
          (a, b) => a.vaccination.nextDueDate.compareTo(b.vaccination.nextDueDate),
        );

      final upcomingEvents = events.where((entry) {
        return entry.event.date.year > 1 && entry.event.date.isAfter(now);
      }).toList(growable: false)
        ..sort((a, b) => a.event.date.compareTo(b.event.date));

      if (!mounted) {
        return;
      }

      setState(() {
        _userName = _firstName(profile.name);
        _pets = uiPets;
        _upcomingEvents = upcomingEvents;
        _overdueVaccineData = overdueVaccines.isEmpty
            ? null
            : _OverdueVaccineData(
                count: overdueVaccines.length,
                detail: _buildVaccineDetailText(
                  overdueVaccines.first,
                  vaccineNamesById,
                ),
                vaccineName: _resolveVaccineName(
                  overdueVaccines.first,
                  vaccineNamesById,
                ),
                entry: overdueVaccines.first,
              );
        _nextVaccine = upcomingVaccines.isEmpty
            ? null
            : _UpcomingVaccineData.fromEntry(
                upcomingVaccines.first,
                vaccineNamesById,
              );
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

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return 'PetCare';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _buildVaccineDetailText(
    _VaccinationWithPet entry,
    Map<String, String> vaccineNamesById,
  ) {
    final vaccineName = _resolveVaccineName(entry, vaccineNamesById);
    return '$vaccineName for ${entry.petName}';
  }

  String _resolveVaccineName(
    _VaccinationWithPet entry,
    Map<String, String> vaccineNamesById,
  ) {
    final vaccineId = entry.vaccination.vaccineId.trim();
    final vaccineName = vaccineNamesById[vaccineId] ?? vaccineId;
    return vaccineName.isEmpty ? AppStrings.valueNotAvailable : vaccineName;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildVaccinesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;

    if (_overdueVaccineData == null && _nextVaccine == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Vaccines',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => _goToRecords(Routes.recordsFilterVaccines),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.homeSeeAll,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_overdueVaccineData != null)
          OverdueVaccinesCard(
            overdueCount: _overdueVaccineData!.count,
            vaccineDetails: _overdueVaccineData!.detail,
            onTap: () => _editVaccine(
              _overdueVaccineData!.entry,
              _overdueVaccineData!.vaccineName,
            ),
          ),
        if (_nextVaccine != null)
          UpcomingVaccineCard(
            vaccineName: _nextVaccine!.vaccineName,
            petName: _nextVaccine!.petName,
            date: _formatDate(_nextVaccine!.date),
            daysUntil: _nextVaccine!.daysUntil,
            onTap: () => _editVaccine(
              _nextVaccine!.entry,
              _nextVaccine!.vaccineName,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(child: _buildBody()),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: () => Navigator.pushNamed(context, Routes.addPet),
        onAddVaccine: _goToAddVaccine,
        onAddEvent: _goToAddEvent,
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.onSurfaceDark
                      : AppColors.grey700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              OutlinedButton(
                onPressed: _loadHomeData,
                child: const Text(AppStrings.petsRetry),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(
            userName: _userName,
            hasNotification: false,
            onNotificationTap: () => _showUnavailableMessage(),
            onNfcTap: () => Navigator.of(context).pushNamed(Routes.nfc),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _buildPetsSection(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildVaccinesSection(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildUpcomingEventsSection(),
          const SizedBox(height: AppDimensions.spaceXXL),
        ],
      ),
    );
  }

  Widget _buildPetsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.homePetsSection,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.pets),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.homeSeeAll,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        if (_pets.isEmpty)
          _buildEmptyPetsState()
        else
          _buildPetsHorizontalList(),
      ],
    );
  }

  Widget _buildPetsHorizontalList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: Row(
        children: [
          ..._pets.map(
            (pet) => Padding(
              padding: const EdgeInsets.only(
                right: AppDimensions.spaceM,
              ),
              child: PetCard(
                pet: pet,
                onTap: () => _goToPetDetail(pet),
              ),
            ),
          ),
          // Add Pet Button
          Padding(
            padding: const EdgeInsets.only(
              right: AppDimensions.spaceM,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: AppColors.primary,
                      width: AppDimensions.strokeThin,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, Routes.addPet),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Add Pet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPetsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.petCardQuickActionBgDark
              : const Color(0x339FF2E2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No pets yet',
              style: TextStyle(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Start by adding your first pet to track their health journey',
              style: TextStyle(
                color: isDark
                    ? AppColors.onSurfaceDark.withValues(alpha: 0.78)
                    : AppColors.addPetBannerText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.addPet),
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventsCardColor = isDark ? AppColors.secondaryDark : AppColors.secondary;
    final dividerColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final events = _upcomingEvents.take(3).toList(growable: false);
    final titleColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.homeActiveEvents,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () =>
                    _goToRecords(Routes.recordsFilterEvents),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.homeSeeAll,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontalPadding,
          ),
          child: events.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    color: eventsCardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  child: Text(
                    'No upcoming events yet.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.onBackgroundDark
                          : AppColors.onSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: eventsCardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(events.length, (index) {
                      final event = events[index];
                      final isLast = index == events.length - 1;

                      return Column(
                        children: [
                          EventCard(
                            eventName: event.event.title,
                            petName: event.petName,
                            date: _formatDate(event.event.date),
                            hasReminder: event.event.followUpDate != null,
                            isGrouped: true,
                            onTap: () => _editEvent(event),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              thickness: AppDimensions.strokeThin,
                              color: dividerColor,
                              indent: AppDimensions.spaceM + 44,
                              endIndent: AppDimensions.spaceM,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
          ),
      ],
    );
  }
}

class _HomeEventEntry {
  const _HomeEventEntry({
    required this.event,
    required this.petId,
    required this.petName,
  });

  final EventModel event;
  final String petId;
  final String petName;
}

class _VaccinationWithPet {
  const _VaccinationWithPet({
    required this.petId,
    required this.petName,
    required this.vaccination,
  });

  final String petId;
  final String petName;
  final PetVaccinationModel vaccination;
}

class _OverdueVaccineData {
  const _OverdueVaccineData({
    required this.count,
    required this.detail,
    required this.vaccineName,
    required this.entry,
  });

  final int count;
  final String detail;
  final String vaccineName;
  final _VaccinationWithPet entry;
}

class _UpcomingVaccineData {
  const _UpcomingVaccineData({
    required this.vaccineName,
    required this.petName,
    required this.date,
    required this.daysUntil,
    required this.entry,
  });

  final String vaccineName;
  final String petName;
  final DateTime date;
  final int daysUntil;
  final _VaccinationWithPet entry;

  factory _UpcomingVaccineData.fromEntry(
    _VaccinationWithPet entry,
    Map<String, String> vaccineNamesById,
  ) {
    final vaccineId = entry.vaccination.vaccineId.trim();
    final vaccineName = vaccineNamesById[vaccineId] ?? vaccineId;
    final now = DateTime.now();
    final dueDate = entry.vaccination.nextDueDate;
    final daysUntil = dueDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    return _UpcomingVaccineData(
      vaccineName: vaccineName.isEmpty
          ? AppStrings.valueNotAvailable
          : vaccineName,
      petName: entry.petName,
      date: dueDate,
      daysUntil: daysUntil,
      entry: entry,
    );
  }
}
