
import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/records/widgets/vaccine_card.dart';
import 'package:flutter_frontend/shared/widgets/filter_toggle_bar.dart';

class RecordsPage extends StatefulWidget{
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();

}

class _RecordsPageState extends State<RecordsPage>{
  int _selectedFilterIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _filters[_selectedFilterIndex].label;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18.0, left:16.0),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedLabel,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  VaccineCard(
                    vaccineName: 'Rabies',
                    petName: 'Max',
                    dateAdministered: DateTime(2026, 2, 24),
                    status: 'active',
                    administeredBy: 'Dr. Smith',
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}
