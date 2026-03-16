import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
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

  late final List<_RecordEntry> _records = [
    _RecordEntry(
      type: _RecordType.vaccine,
      title: 'Rabies',
      subtitle: 'Max · Dr. Smith',
      meta: 'Feb 24, 2026',
      icon: Icons.vaccines_outlined,
      iconBackground: AppColors.primaryVariant,
      iconColor: AppColors.primary,
    ),
    _RecordEntry(
      type: _RecordType.event,
      title: AppStrings.recordCheckup,
      subtitle:
        '${AppStrings.recordPetMax} · ${AppStrings.recordClinicHappyPaws}',
      meta: '${AppStrings.recordDateNov19} · ${AppStrings.recordCost120}',
      icon: Icons.assignment_outlined,
      iconBackground: AppColors.primaryVariant,
      iconColor: AppColors.primary,
    ),
    _RecordEntry(
      type: _RecordType.event,
      title: AppStrings.recordCheckup,
      subtitle:
          '${AppStrings.recordPetLuna} · ${AppStrings.recordClinicCatCare}',
      meta: '${AppStrings.recordDateOct14} · ${AppStrings.recordCost95}',
      icon: Icons.assignment_outlined,
      iconBackground: AppColors.primaryVariant,
      iconColor: AppColors.primary,
    ),
    _RecordEntry(
      type: _RecordType.event,
      title: AppStrings.recordEmergency,
      subtitle:
          '${AppStrings.recordPetLuna} · ${AppStrings.recordClinicCityEmergency}',
      meta: '${AppStrings.recordDateAug29} · ${AppStrings.recordCost340}',
      icon: Icons.medical_services_outlined,
      iconBackground: AppColors.negativeBackground,
      iconColor: AppColors.negativeText,
    ),
    _RecordEntry(
      type: _RecordType.event,
      title: AppStrings.recordDental,
      subtitle:
          '${AppStrings.recordPetMax} · ${AppStrings.recordClinicCityVet}',
      meta: '${AppStrings.recordDateJun4} · ${AppStrings.recordCost280}',
      icon: Icons.healing_outlined,
      iconBackground: AppColors.positiveBackground,
      iconColor: AppColors.positiveText,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex >= Routes.recordsFilterAll &&
            widget.initialFilterIndex <= Routes.recordsFilterEvents
        ? widget.initialFilterIndex
        : Routes.recordsFilterAll;
  }

  void navigateToDetail(_RecordType type) {
    if (type == _RecordType.vaccine) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DetailPage(type: 'vaccine',)));
      return;
    } else if (type == _RecordType.event) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DetailPage(type: 'event',)));
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

  void _goToAddVaccine() {
    Navigator.of(context).pushNamed(Routes.addVaccine);
  }

  void _goToAddEvent() {
    Navigator.of(context).pushNamed(Routes.addEvent);
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
                      onTap: () => navigateToDetail(record.type),
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
  });

  final _RecordType type;
  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}
