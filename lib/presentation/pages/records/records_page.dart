import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/models/pet_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/event_service.dart';
import 'package:flutter_frontend/core/services/pet_service.dart';
import 'package:flutter_frontend/core/services/telemetry_service.dart';
import 'package:flutter_frontend/core/services/vaccine_service.dart';
import 'package:flutter_frontend/core/services/medicine_service.dart';
import 'package:flutter_frontend/core/models/medicine_model.dart';
import 'package:flutter_frontend/presentation/pages/records/widgets/record_list_item.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../shared/widgets/filter_toggle_bar.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import 'detail/detail_page.dart';
import '../medicine_detail/medicine_detail_args.dart';

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

  final PetService _petService = PetService();
  final VaccineService _vaccineService = VaccineService();
  final MedicineService _medicineService = MedicineService();
  final EventService _eventService = EventService();
  final TelemetryService _telemetryService = TelemetryService();


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
    const FilterOption(
      label: AppStrings.recordsFilterMedicines,
      icon: Icons.medication,
    ),
  ];

  List<_RecordEntry> _records = [];

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex >= Routes.recordsFilterAll &&
          widget.initialFilterIndex <= Routes.recordsFilterMedicines
        ? widget.initialFilterIndex
        : Routes.recordsFilterAll;
      _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _petService.getPets(),
        _vaccineService.getVaccines(),
        // medicines fetched per pet below, but include a placeholder call to ensure service readiness
        Future.value(<dynamic>[]),
      ]);
      final pets = results[0] as List<PetModel>;
      final vaccineCatalog = results[1] as List<dynamic>;

      final petVaccinations = <String, List<PetVaccinationModel>>{
        for (final pet in pets) pet.id: pet.vaccinations,
      };

      final petEventEntries = await Future.wait(
        pets.map((pet) async {
          try {
            final events = await _eventService.getEventsByPet(pet.id);
            return MapEntry<String, List<EventModel>>(pet.id, events);
          } catch (_) {
            return const MapEntry<String, List<EventModel>>('', <EventModel>[]);
          }
        }),
      );
      final petEvents = <String, List<EventModel>>{
        for (final entry in petEventEntries)
          if (entry.key.isNotEmpty) entry.key: entry.value,
      };

      final vaccineIds = petVaccinations.values
        .expand((vaccinations) => vaccinations)
        .map((vaccine) => vaccine.vaccineId)
        .toSet()
        .toList(growable: false);

      final vaccineInfoMap = <String, String>{
        for (final vaccine in vaccineCatalog)
          if (vaccine.id.trim().isNotEmpty)
            vaccine.id.trim(): vaccine.name.trim().isEmpty
                ? AppStrings.valueNotAvailable
                : vaccine.name.trim(),
      };
      for (final vaccineId in vaccineIds.where((id) => !vaccineInfoMap.containsKey(id))) {
        vaccineInfoMap[vaccineId] = AppStrings.valueNotAvailable;
      }

      if (!mounted) {
        return;
      }
      // fetch medicines for all pets
      final petIds = pets.map((p) => p.id).where((id) => id.trim().isNotEmpty).toList(growable: false);
      final petMedicines = await _medicineService.getMedicinesForPets(petIds);

      setState(() {
        final vaccineRecords = _buildVaccineRecords(
          pets,
          petVaccinations,
          vaccineInfoMap,
        );
        final eventRecords = _buildEventRecords(pets, petEvents);
        final medicineRecords = _buildMedicineRecords(pets, petMedicines);

        _records = [...vaccineRecords, ...medicineRecords, ...eventRecords]
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
            iconBackground: AppColors.petStatusHealthyBg,
            iconColor: AppColors.primary,
            iconAssetPath: AppAssets.iconVaccine,
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
            iconBackground: AppColors.appointmentBackground,
            iconColor: AppColors.primary,
            iconAssetPath: AppAssets.iconVetCheckClean,
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

  List<_RecordEntry> _buildMedicineRecords(
    List<PetModel> pets,
    List<MedicineModel> medicines,
  ) {
    final records = <_RecordEntry>[];
    final medicinesByPet = <String, List<MedicineModel>>{};
    for (final med in medicines) {
      final pid = med.petId;
      medicinesByPet.putIfAbsent(pid, () => []).add(med);
    }

    for (final pet in pets) {
      final meds = medicinesByPet[pet.id] ?? const <MedicineModel>[];
      for (final med in meds) {
        final title = med.medicineName.trim().isNotEmpty ? med.medicineName.trim() : AppStrings.valueNotAvailable;
        final subtitle = '${pet.name} - ${med.administrationRoute.trim().isNotEmpty ? med.administrationRoute : AppStrings.valueNotAvailable}';
        final meta = med.startDate != null ? _formatDate(med.startDate!) : AppStrings.valueNotAvailable;
        final sortDate = med.startDate ?? DateTime(0);

        records.add(
          _RecordEntry(
            type: _RecordType.medicine,
            title: title,
            subtitle: subtitle,
            meta: meta,
            icon: Icons.medication,
            iconBackground: AppColors.infoBackground,
            iconColor: AppColors.infoText,
            iconAssetPath: null,
            sortDate: sortDate,
            medicine: med,
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
          settings: const RouteSettings(name: Routes.vaccineDetail),
          builder: (context) => DetailPage(
            type: 'vaccine',
            vaccination: record.vaccination,
            pet: record.pet,
            vaccineName: record.title,
          )
        )
      );
      if (result == true) {
        await _loadRecords();
      }
      return;
    } else if (record.type == _RecordType.event) {
      final result = await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: Routes.eventDetail),
          builder: (context) => DetailPage(
            type: 'event',
            event: record.event,
            pet: record.pet,
          ),
        ),
      );

      if (result == true) {
        await _loadRecords();
      }

      return;
    } else if (record.type == _RecordType.medicine) {
      if (record.pet == null || record.medicine == null) {
        _showUnavailableMessage();
        return;
      }

      final result = await Navigator.of(context).pushNamed(
        Routes.medicineDetail,
        arguments: MedicineDetailArgs(
          medicine: record.medicine!,
          pet: record.pet!,
        ),
      );

      if (result == true) {
        await _loadRecords();
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
      await _loadRecords();
    }
  }

  Future<void> _goToAddEvent() async {
    final result = await Navigator.of(context).pushNamed(Routes.addEvent);
    if (result == true) {
      await _loadRecords();
    }
  }
  
  Future<void> _goToAddPet() async {
    final result = await Navigator.of(context).pushNamed(Routes.addPet);
    if (!mounted || result != true) {
      return;
    }
    await _telemetryService.logAddPetExecutionIfPending(
      endTime: DateTime.now(),
    );
  }

  Future<void> _goToAddMedicine() async {
    final result = await Navigator.of(context).pushNamed(Routes.addMedicine);
    if (result == true) {
      await _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _filters[_selectedFilterIndex].label;
    final filteredRecords = _records.where((record) {
      if (_selectedFilterIndex == Routes.recordsFilterVaccines) {
        return record.type == _RecordType.vaccine;
      }
      if (_selectedFilterIndex == Routes.recordsFilterMedicines) {
        return record.type == _RecordType.medicine;
      }
      if (_selectedFilterIndex == Routes.recordsFilterEvents) {
        return record.type == _RecordType.event;
      }
      return true;
    }).toList();
    final (emptyMessage, emptyIcon) =
        _emptyPresentationForFilter(_selectedFilterIndex);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: _goToAddPet,
        onAddVaccine: _goToAddVaccine,
        onAddMedicine: _goToAddMedicine,
        onAddEvent: _goToAddEvent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        if (filteredRecords.isEmpty)
                          _EmptyRecordsState(
                            message: emptyMessage,
                            icon: emptyIcon,
                          )
                        else
                          for (final record in filteredRecords)
                            RecordListItem(
                              title: record.title,
                              subtitle: record.subtitle,
                              meta: record.meta,
                              icon: record.icon,
                              iconBackground: record.iconBackground,
                              iconColor: record.iconColor,
                              iconAssetPath: record.iconAssetPath,
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

  (String, IconData) _emptyPresentationForFilter(int filterIndex) {
    if (filterIndex == Routes.recordsFilterVaccines) {
      return ('No vaccine records yet.', Icons.vaccines_outlined);
    }
    if (filterIndex == Routes.recordsFilterMedicines) {
      return ('No medicine records yet.', Icons.medication);
    }
    if (filterIndex == Routes.recordsFilterEvents) {
      return ('No event records yet.', Icons.event_note_outlined);
    }
    return ('No records yet.', Icons.folder_open_rounded);
  }
}

class _EmptyRecordsState extends StatelessWidget {
  const _EmptyRecordsState({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.grey300.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppColors.grey500.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RecordType { vaccine, medicine, event }

class _RecordEntry {
  const _RecordEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.iconAssetPath,
    required this.sortDate,
    this.vaccination,
    this.event,
    this.medicine,
    this.pet,
  });

  final _RecordType type;
  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String? iconAssetPath;
  final DateTime sortDate;
  final PetVaccinationModel? vaccination;
  final EventModel? event;
  final MedicineModel? medicine;
  final PetModel? pet;
}
