import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/home/home_page.dart';
import 'package:flutter_frontend/presentation/pages/records/widgets/record_list_item.dart';
import 'package:flutter_frontend/presentation/pages/vaccine_detail/vaccine_detail_page.dart';
import 'package:flutter_frontend/shared/widgets/filter_toggle_bar.dart';
import 'package:flutter_frontend/shared/widgets/petcare_bottom_nav_bar.dart';
import 'package:flutter_frontend/shared/widgets/quick_actions_fab.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _selectedFilterIndex = 0;
  int _currentIndex = 2;

  void _replaceWithoutAnimation(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

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

  void navigateToVaccineDetail() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const VaccineDetailPage()));
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) {
      return;
    }

    if (index == 0) {
      _replaceWithoutAnimation(const HomePage());
      return;
    }

    if (index == 2) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _goToAddVaccine() {
    Navigator.of(context).pushNamed(Routes.addVaccine);
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
        onAddPet: () {},
        onAddVaccine: _goToAddVaccine,
        onAddEvent: () {},
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
                      onTap: navigateToVaccineDetail,
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
