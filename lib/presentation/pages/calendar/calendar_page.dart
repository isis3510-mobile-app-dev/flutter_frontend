import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/event_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/vaccine_service.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import '../pets/models/pet_ui_mapper.dart';
import '../pets/models/pet_ui_model.dart';
import 'widgets/calendar_strip.dart';
import 'widgets/empty_events_state.dart';
import 'widgets/event_timeline_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const int _currentIndex = 3;

  final PetService _petService = PetService();
  final VaccineService _vaccineService = VaccineService();
  final EventService _eventService = EventService();

  bool _isLoading = false;

  DateTime _focusedMonth = _monthStart(DateTime.now());
  DateTime _selectedDate = _dateOnly(DateTime.now());
  List<PetUiModel> _pets = const [];
  List<_CalendarEvent> _events = const [];
  _CalendarEventFilter _selectedEventFilter = _CalendarEventFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _petService.getPets(),
        _vaccineService.getVaccines(),
      ]);

      final pets = results[0] as List<PetModel>;
      final vaccineCatalog = results[1] as List<dynamic>;

      final mappedPets = pets
          .map((pet) => pet.toUiModel())
          .toList(growable: false);

      final petVaccinations = <String, List<PetVaccinationModel>>{
        for (final pet in pets) pet.id: pet.vaccinations,
      };

      final petEventEntries = await Future.wait(
        pets.map((pet) async {
          try {
            final events = await _eventService.getEventsByPet(pet.id);
            return MapEntry<String, List<EventModel>>(pet.id, events);
          } catch (_) {
            return MapEntry<String, List<EventModel>>(
              pet.id,
              const <EventModel>[],
            );
          }
        }),
      );

      final petEvents = <String, List<EventModel>>{
        for (final entry in petEventEntries) entry.key: entry.value,
      };

      final vaccineIds = petVaccinations.values
          .expand((vaccinations) => vaccinations)
          .map((vaccination) => vaccination.vaccineId.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final vaccineInfoMap = <String, String>{
        for (final vaccine in vaccineCatalog)
          if (vaccine.id.trim().isNotEmpty)
            vaccine.id.trim(): vaccine.name.trim().isEmpty
                ? AppStrings.valueNotAvailable
                : vaccine.name.trim(),
      };
      for (final vaccineId in vaccineIds.where(
        (id) => !vaccineInfoMap.containsKey(id),
      )) {
        vaccineInfoMap[vaccineId] = AppStrings.valueNotAvailable;
      }

      final calendarEvents = _buildCalendarEvents(
        pets: pets,
        petVaccinations: petVaccinations,
        petEvents: petEvents,
        vaccineInfoMap: vaccineInfoMap,
      );

      final nextSelectedDate = _resolveSelectedDateAfterLoad(calendarEvents);

      if (!mounted) {
        return;
      }

      setState(() {
        _pets = mappedPets;
        _events = calendarEvents;
        _selectedDate = nextSelectedDate;
        _focusedMonth = _monthStart(nextSelectedDate);
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));

      setState(() {
        _pets = const [];
        _events = const [];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));

      setState(() {
        _pets = const [];
        _events = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<_CalendarEvent> _buildCalendarEvents({
    required List<PetModel> pets,
    required Map<String, List<PetVaccinationModel>> petVaccinations,
    required Map<String, List<EventModel>> petEvents,
    required Map<String, String> vaccineInfoMap,
  }) {
    final calendarEvents = <_CalendarEvent>[];

    for (final pet in pets) {
      final petClinic = pet.defaultClinic.trim().isNotEmpty
          ? pet.defaultClinic.trim()
          : AppStrings.valueNotAvailable;

      final vaccinations = petVaccinations[pet.id] ?? pet.vaccinations;

      for (final vaccination in vaccinations) {
        final startsAt = _resolveVaccinationDate(vaccination);
        if (!_isValidDate(startsAt)) {
          continue;
        }

        final vaccineTitle =
            vaccineInfoMap[vaccination.vaccineId.trim()] ??
            AppStrings.valueNotAvailable;
        final clinicName = vaccination.clinicName.trim().isNotEmpty
            ? vaccination.clinicName.trim()
            : petClinic;
        final vaccinationId = vaccination.id.trim();

        calendarEvents.add(
          _CalendarEvent(
            id: vaccinationId.isNotEmpty
                ? 'vaccine-$vaccinationId'
                : 'vaccine-${pet.id}-${startsAt.toIso8601String()}',
            petId: pet.id,
            title: vaccineTitle,
            clinicName: clinicName,
            startsAt: startsAt,
            type: _CalendarEventType.vaccine,
          ),
        );
      }

      final events = petEvents[pet.id] ?? const <EventModel>[];
      for (final event in events) {
        if (!_isValidDate(event.date)) {
          continue;
        }

        final eventId = event.id.trim().isNotEmpty
            ? event.id.trim()
            : '${pet.id}-${event.date.toIso8601String()}';
        final title = event.title.trim().isNotEmpty
            ? event.title.trim()
            : _formatEventTypeLabel(event.eventType);

        calendarEvents.add(
          _CalendarEvent(
            id: 'event-$eventId',
            petId: pet.id,
            title: title,
            clinicName: _resolveEventLocation(
              clinic: event.clinic,
              provider: event.provider,
              petDefaultClinic: petClinic,
            ),
            startsAt: event.date,
            type: _mapEventType(event.eventType),
          ),
        );
      }
    }

    return calendarEvents;
  }

  DateTime _resolveVaccinationDate(PetVaccinationModel vaccination) {
    if (_isValidDate(vaccination.dateGiven)) {
      return vaccination.dateGiven;
    }

    return vaccination.nextDueDate;
  }

  DateTime _resolveSelectedDateAfterLoad(List<_CalendarEvent> events) {
    final currentSelected = _dateOnly(_selectedDate);
    if (events.any((event) => _isSameDay(event.startsAt, currentSelected))) {
      return currentSelected;
    }

    if (events.isEmpty) {
      return currentSelected;
    }

    final eventDates =
        events
            .map((event) => _dateOnly(event.startsAt))
            .toSet()
            .toList(growable: false)
          ..sort((left, right) => left.compareTo(right));

    final today = _dateOnly(DateTime.now());
    for (final date in eventDates) {
      if (!date.isBefore(today)) {
        return date;
      }
    }

    return eventDates.last;
  }

  String _resolveEventLocation({
    required String clinic,
    required String provider,
    required String petDefaultClinic,
  }) {
    final clinicName = clinic.trim();
    if (clinicName.isNotEmpty) {
      return clinicName;
    }

    final providerName = provider.trim();
    if (providerName.isNotEmpty) {
      return providerName;
    }

    return petDefaultClinic;
  }

  _CalendarEventType _mapEventType(String rawType) {
    final normalized = rawType.trim().toLowerCase();

    if (normalized.contains('vaccin') || normalized.contains('vacun')) {
      return _CalendarEventType.vaccine;
    }

    if (normalized.contains('dental')) {
      return _CalendarEventType.dental;
    }

    if (normalized.contains('groom') ||
        normalized.contains('bath') ||
        normalized.contains('bano')) {
      return _CalendarEventType.grooming;
    }

    return _CalendarEventType.appointment;
  }

  String _formatEventTypeLabel(String rawType) {
    final normalized = rawType.trim();
    if (normalized.isEmpty) {
      return AppStrings.valueNotAvailable;
    }

    final words = normalized
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return AppStrings.valueNotAvailable;
    }

    return words
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  bool _isValidDate(DateTime? value) {
    if (value == null) {
      return false;
    }

    return value.year > 1;
  }

  List<_CalendarEvent> get _selectedDayEvents {
    final eventsForDate = _events.where(
      (event) => _isSameDay(event.startsAt, _selectedDate),
    );

    final filteredEvents = eventsForDate.where(_matchesEventFilter);

    final sorted = filteredEvents.toList(growable: false)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));

    return sorted;
  }

  List<_CalendarFilterOption> get _eventFilterOptions {
    final options = <_CalendarFilterOption>[
      const _CalendarFilterOption(
        filter: _CalendarEventFilter.all,
        label: AppStrings.recordsFilterAll,
      ),
      const _CalendarFilterOption(
        filter: _CalendarEventFilter.vaccines,
        label: AppStrings.recordsFilterVaccines,
      ),
      const _CalendarFilterOption(
        filter: _CalendarEventFilter.appointments,
        label: AppStrings.calendarFilterAppointments,
      ),
    ];

    return options;
  }

  bool _matchesEventFilter(_CalendarEvent event) {
    return switch (_selectedEventFilter) {
      _CalendarEventFilter.all => true,
      _CalendarEventFilter.vaccines => event.type == _CalendarEventType.vaccine,
      _CalendarEventFilter.appointments =>
        event.type != _CalendarEventType.vaccine,
    };
  }

  String get _selectedDateLabel {
    return '${_selectedDate.day} ${_monthName(_selectedDate.month).toUpperCase()}';
  }

  String get _focusedMonthLabel {
    return '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.featureUnavailable)),
    );
  }

  void _goToPreviousMonth() {
    _changeFocusedMonth(-1);
  }

  void _goToNextMonth() {
    _changeFocusedMonth(1);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _focusedMonth = _monthStart(date);
    });
  }

  void _changeFocusedMonth(int monthDelta) {
    final nextFocusedMonth = _monthStart(
      DateTime(_focusedMonth.year, _focusedMonth.month + monthDelta),
    );
    final maxDayInNextMonth = _daysInMonth(
      nextFocusedMonth.year,
      nextFocusedMonth.month,
    );
    final clampedDay = _selectedDate.day > maxDayInNextMonth
        ? maxDayInNextMonth
        : _selectedDate.day;

    setState(() {
      _focusedMonth = nextFocusedMonth;
      _selectedDate = DateTime(
        nextFocusedMonth.year,
        nextFocusedMonth.month,
        clampedDay,
      );
    });
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

  Future<void> _goToAddEvent() async {
    final result = await Navigator.of(context).pushNamed(Routes.addEvent);
    if (result == true) {
      _loadCalendarData();
    }
  }

  Future<void> _goToAddPet() async {
    final result = await Navigator.of(context).pushNamed(Routes.addPet);
    if (result == true) {
      _loadCalendarData();
    }
  }

  Future<void> _goToAddVaccine() async {
    final result = await Navigator.of(context).pushNamed(Routes.addVaccine);
    if (result == true) {
      _loadCalendarData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackground;
    final sectionLabelColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final selectedDayEvents = _selectedDayEvents;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          AppStrings.calendarTitle,
          style: TextStyle(
            color: titleColor,
            fontSize: AppDimensions.calendarTitleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceM,
              ),
              child: CalendarStrip(
                focusedMonth: _focusedMonth,
                monthLabel: _focusedMonthLabel,
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
                onPreviousMonth: _goToPreviousMonth,
                onNextMonth: _goToNextMonth,
              ),
            ),
            SizedBox(
              height: AppDimensions.calendarChipHeight,
              child: _buildEventFilters(isDark),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
              ),
              child: Text(
                _selectedDateLabel,
                style: TextStyle(
                  color: sectionLabelColor,
                  fontSize: AppDimensions.calendarSectionLabelFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppDimensions.letterSpacingSection,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedDayEvents.isEmpty
                  ? EmptyEventsState(onAddEvent: _goToAddEvent)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pageHorizontalPadding,
                        0,
                        AppDimensions.pageHorizontalPadding,
                        AppDimensions.spaceXXL,
                      ),
                      itemCount: selectedDayEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimensions.spaceM),
                      itemBuilder: (context, index) {
                        final event = selectedDayEvents[index];

                        return KeyedSubtree(
                          key: ValueKey(event.id),
                          child: EventTimelineCard(
                            timeLabel: event.timeLabel,
                            title: event.title,
                            subtitle:
                                '${_petNameForId(event.petId)} • ${event.clinicName}',
                            iconAssetPath: event.iconAssetPath,
                            cardColor: _eventCardColor(event.type, isDark),
                            isLast: index == selectedDayEvents.length - 1,
                          ),
                        );
                      },
                    ),
            ),
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
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildEventFilters(bool isDark) {
    final options = _eventFilterOptions;
    final inactiveBackground = isDark
        ? AppColors.surfaceDark
        : AppColors.surface;
    final inactiveTextColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.grey700;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      itemCount: options.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppDimensions.spaceXS),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option.filter == _selectedEventFilter;

        return _CalendarFilterChip(
          label: option.label,
          isSelected: isSelected,
          inactiveBackground: inactiveBackground,
          inactiveTextColor: inactiveTextColor,
          onTap: () {
            setState(() {
              _selectedEventFilter = option.filter;
            });
          },
        );
      },
    );
  }

  String _petNameForId(String petId) {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet.name;
      }
    }

    return AppStrings.valueNotAvailable;
  }
}

class _CalendarFilterChip extends StatelessWidget {
  const _CalendarFilterChip({
    required this.label,
    required this.isSelected,
    required this.inactiveBackground,
    required this.inactiveTextColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color inactiveBackground;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceXXS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : inactiveBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            border: isSelected
                ? null
                : Border.fromBorderSide(
                    BorderSide(
                      color: isDark
                          ? AppColors.petFilterInactiveBorderDark
                          : AppColors.petFilterInactiveBorder,
                      width: AppDimensions.strokeThin,
                    ),
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.onPrimary : inactiveTextColor,
                fontSize: AppDimensions.calendarChipFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarFilterOption {
  const _CalendarFilterOption({required this.filter, required this.label});

  final _CalendarEventFilter filter;
  final String label;
}

enum _CalendarEventFilter { all, vaccines, appointments }

enum _CalendarEventType { vaccine, appointment, dental, grooming }

class _CalendarEvent {
  const _CalendarEvent({
    required this.id,
    required this.petId,
    required this.title,
    required this.clinicName,
    required this.startsAt,
    required this.type,
  });

  final String id;
  final String petId;
  final String title;
  final String clinicName;
  final DateTime startsAt;
  final _CalendarEventType type;

  String get timeLabel {
    final normalizedHour = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
    final minutes = startsAt.minute.toString().padLeft(2, '0');
    final period = startsAt.hour >= 12 ? 'PM' : 'AM';
    final hourText = normalizedHour.toString().padLeft(2, '0');
    return '$hourText:$minutes $period';
  }

  String get iconAssetPath {
    return switch (type) {
      _CalendarEventType.vaccine => AppAssets.iconVaccine,
      _CalendarEventType.appointment => AppAssets.iconVetCheck,
      _CalendarEventType.dental => AppAssets.iconDentalCheck,
      _CalendarEventType.grooming => AppAssets.iconCalendar,
    };
  }
}

Color _eventCardColor(_CalendarEventType type, bool isDark) {
  return switch (type) {
    _CalendarEventType.vaccine =>
      isDark
          ? AppColors.petDetailHealthSummaryBgDark
          : AppColors.petStatusHealthyBg,
    _CalendarEventType.appointment =>
      isDark ? AppColors.surfaceDark : AppColors.surface,
    _CalendarEventType.dental =>
      isDark
          ? AppColors.addPetReminderBackgroundDark
          : AppColors.positiveBackground,
    _CalendarEventType.grooming =>
      isDark
          ? AppColors.addPetReminderBackgroundDark
          : AppColors.primaryVariant,
  };
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _monthStart(DateTime date) {
  return DateTime(date.year, date.month);
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _monthName(int month) {
  return switch (month) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
    _ => 'Month',
  };
}
