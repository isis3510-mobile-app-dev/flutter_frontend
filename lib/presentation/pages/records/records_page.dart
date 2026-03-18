import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/presentation/pages/records/widgets/record_list_item.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../shared/widgets/filter_toggle_bar.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import 'detail/detail_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    super.key,
    this.initialFilterIndex = Routes.recordsFilterAll,
  });

  final int initialFilterIndex;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late int _selectedFilterIndex;
  static const _currentIndex = 2;

  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final VaccineService _vaccineService = VaccineService();
  final EventService _eventService = EventService();

  bool _isLoading = false;

  late final List<FilterOption> _filters = [
    const FilterOption(
      label: AppStrings.recordsFilterAll,
      icon: Icons.subject_rounded,
    ),
    const FilterOption(
      label: AppStrings.recordsFilterVaccines,
      icon: Icons.vaccines_outlined,
    ),
    const FilterOption(
      label: AppStrings.recordsFilterEvents,
      icon: Icons.event_note_outlined,
    ),
  ];

  List<_RecordEntry> _records = [];

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex >= Routes.recordsFilterAll &&
            widget.initialFilterIndex <= Routes.recordsFilterEvents
        ? widget.initialFilterIndex
        : Routes.recordsFilterAll;
      _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getCurrentUser();
      final petIds = profile.pets
          .map(_extractPetId)
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final pets = <PetModel>[];
      final petVaccinations = <String, List<PetVaccinationModel>>{};
      final petEvents = <String, List<EventModel>>{};
      for (final petId in petIds) {
        try {
          final pet = await _petService.getPetById(petId);
          pets.add(pet);

          try {
            final vaccinations = await _petService.getVaccinations(pet.id);
            petVaccinations[pet.id] = vaccinations;
          } catch (_) {
            petVaccinations[pet.id] = const [];
          }

          try {
            final events = await _eventService.getEventsByPet(pet.id);
            petEvents[pet.id] = events;
          } catch (_) {
            petEvents[pet.id] = const [];
          }
        } catch (_) {
          // Skip missing/invalid pet ids to keep records page working.
        }
      }

      final vaccineIds = petVaccinations.values
        .expand((vaccinations) => vaccinations)
        .map((vaccine) => vaccine.vaccineId)
        .toSet()
        .toList(growable: false);

      final vaccineInfoMap = <String, String>{};
      for (final vaccineId in vaccineIds) {
        try {
          final vaccineInfo = await _vaccineService.getVaccineById(vaccineId);
          vaccineInfoMap[vaccineId] = vaccineInfo.name;
        } catch (_) {
          vaccineInfoMap[vaccineId] = AppStrings.valueNotAvailable;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        final vaccineRecords = _buildVaccineRecords(
          pets,
          petVaccinations,
          vaccineInfoMap,
        );
        final eventRecords = _buildEventRecords(pets, petEvents);

        _records = [...vaccineRecords, ...eventRecords]
          ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_RecordEntry> _buildVaccineRecords(
    List<PetModel> pets,
    Map<String, List<PetVaccinationModel>> petVaccinations,
    Map<String, String> vaccineInfoMap,
  ) {
    final records = <_RecordEntry>[];
    for (final pet in pets) {
      final vaccinations = petVaccinations[pet.id] ?? const [];
      for (final vaccine in vaccinations) {
        records.add(
          _RecordEntry(
            type: _RecordType.vaccine,
            title: vaccineInfoMap[vaccine.vaccineId] ?? AppStrings.valueNotAvailable,
            subtitle: _buildVaccineSubtitle(pet, vaccine.administeredBy),
            meta: _formatDate(vaccine.dateGiven),
            icon: Icons.vaccines_outlined,
            iconBackground: AppColors.primaryVariant,
            iconColor: AppColors.primary,
            sortDate: vaccine.dateGiven,
            vaccination: vaccine,
            pet: pet,
          ),
        );
      }
    }

    records.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return records;
  }

  List<_RecordEntry> _buildEventRecords(
    List<PetModel> pets,
    Map<String, List<EventModel>> petEvents,
  ) {
    final records = <_RecordEntry>[];
    for (final pet in pets) {
      final events = petEvents[pet.id] ?? const <EventModel>[];
      for (final event in events) {
        records.add(
          _RecordEntry(
            type: _RecordType.event,
            title: event.title.trim().isNotEmpty
                ? event.title.trim()
                : AppStrings.valueNotAvailable,
            subtitle: _buildEventSubtitle(pet, event),
            meta: _buildEventMeta(event),
            icon: Icons.event_note_outlined,
            iconBackground: AppColors.primaryVariant,
            iconColor: AppColors.primary,
            sortDate: event.date,
            event: event,
            pet: pet,
          ),
        );
      }
    }

    records.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return records;
  }

  String _buildEventSubtitle(PetModel pet, EventModel event) {
    final displaySource = event.provider.trim().isNotEmpty
        ? event.provider.trim()
        : event.clinic.trim().isNotEmpty
            ? event.clinic.trim()
            : AppStrings.valueNotAvailable;

    return '${pet.name} - $displaySource';
  }

  String _buildEventMeta(EventModel event) {
    final dateText = _formatDate(event.date);
    final priceText = event.price == null
        ? ''
        : ' • \$${event.price!.toStringAsFixed(2)}';
    return '$dateText$priceText';
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
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String _buildVaccineSubtitle(PetModel pet, String vetName) {
    final displayVet = vetName.trim().isNotEmpty
        ? vetName.trim()
        : pet.defaultVet.trim().isNotEmpty
            ? pet.defaultVet.trim()
            : AppStrings.valueNotAvailable;
    return '${pet.name} - $displayVet';
  }

  Future<void> navigateToDetail(_RecordEntry record) async {
    if (record.type == _RecordType.vaccine) {
      final result = await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (context) => DetailPage(
            type: 'vaccine',
            vaccination: record.vaccination,
            pet: record.pet,
            vaccineName: record.title,
          )
        )
      );
      if (result == true) {
        _loadRecords();
      }
      return;
    } else if (record.type == _RecordType.event) {
      final result = await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (context) => DetailPage(
            type: 'event',
            event: record.event,
            pet: record.pet,
          ),
        ),
      );

      if (result == true) {
        _loadRecords();
      }

      return;
    }
    return;
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

  Future<void> _goToAddVaccine() async {
    final result = await Navigator.of(context).pushNamed(Routes.addVaccine);
    if (result == true) {
      _loadRecords();
    }
  }

  String _extractPetId(dynamic pet) {
    if (pet is String) {
      return pet;
    }
    if (pet is Map) {
      final id = pet['id'] ?? pet['petId'] ?? pet['pet_id'];
      if (id != null) {
        return id.toString();
      }
    }
    return pet?.toString() ?? '';
  }

  Future<void> _goToAddEvent() async {
    final result = await Navigator.of(context).pushNamed(Routes.addEvent);
    if (result == true) {
      _loadRecords();
    }
  }
  
  void _goToAddPet() {
    Navigator.of(context).pushNamed(Routes.addPet);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _filters[_selectedFilterIndex].label;
    final filteredRecords = _records.where((record) {
      if (_selectedFilterIndex == 1) {
        return record.type == _RecordType.vaccine;
      }
      if (_selectedFilterIndex == 2) {
        return record.type == _RecordType.event;
      }
      return true;
    }).toList();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: _goToAddPet,
        onAddVaccine: _goToAddVaccine,
        onAddEvent: _goToAddEvent,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(top: 18.0, left: 16.0),
              child: Text(
                AppStrings.healthRecordsTitle,
                style: context.textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: FilterToggleBar(
                selectedIndex: _selectedFilterIndex,
                onSelected: (index) {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                filters: _filters,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedLabel,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final record in filteredRecords)
                    RecordListItem(
                      title: record.title,
                      subtitle: record.subtitle,
                      meta: record.meta,
                      icon: record.icon,
                      iconBackground: record.iconBackground,
                      iconColor: record.iconColor,
                      onTap: () => navigateToDetail(record),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}

enum _RecordType { vaccine, event }

class _RecordEntry {
  const _RecordEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.sortDate,
    this.vaccination,
    this.event,
    this.pet,
  });

  final _RecordType type;
  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final DateTime sortDate;
  final PetVaccinationModel? vaccination;
  final EventModel? event;
  final PetModel? pet;
}
