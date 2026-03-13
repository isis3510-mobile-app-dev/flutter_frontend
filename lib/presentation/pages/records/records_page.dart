import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/home/home_page.dart';
import 'package:flutter_frontend/presentation/pages/records/widgets/vaccine_card.dart';
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
                    onTap: navigateToVaccineDetail,
                  ),
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
