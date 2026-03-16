import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';
import '../pets/data/pets_mock_data.dart';
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
  late final List<PetUiModel> _pets;

  @override
  void initState() {
    super.initState();
    _pets = PetsMockData.all;
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

  void _goToRecords(int initialFilterIndex) {
    Navigator.of(
      context,
    ).pushNamed(Routes.records, arguments: initialFilterIndex);
  }

  @override
  Widget build(BuildContext context) {
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              HomeHeader(
                userName: 'Sarah',
                hasNotification: false,
                onNotificationTap: () => _showUnavailableMessage(),
                onNfcTap: () => _showUnavailableMessage(),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Pets Section
              _buildPetsSection(),
              const SizedBox(height: AppDimensions.spaceL),

              // Overdue Vaccines Alert
              if (_hasOverdueVaccines())
                OverdueVaccinesCard(
                  overdueCount: 2,
                  vaccineDetails: 'Leptospirosis for Max',
                  onTap: () => _goToRecords(Routes.recordsFilterVaccines),
                ),

              // Upcoming Vaccine Card
              UpcomingVaccineCard(
                vaccineName: 'Rabies',
                petName: 'Max',
                date: 'Mar 14, 2025',
                daysUntil: 349,
                onTap: () => _goToRecords(Routes.recordsFilterVaccines),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Upcoming Events Section
              _buildUpcomingEventsSection(),
              const SizedBox(height: AppDimensions.spaceXXL),
            ],
          ),
        ),
      ),
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

  Widget _buildPetsSection() {
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
                style: const TextStyle(
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
                    color: AppColors.onSurface,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: const Color(0x339FF2E2), // AppColors.primaryVariant with 20% opacity
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No pets yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Start by adding your first pet to track their health journey',
              style: TextStyle(
                color: AppColors.addPetBannerText,
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
    final eventsCardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final dividerColor = isDark ? AppColors.grey700 : AppColors.grey300;

    final events = [
      {
        'name': 'Vet Check-up',
        'pet': 'Max',
        'date': 'March 3',
        'hasReminder': true,
      },
      {
        'name': 'Vet Check-up',
        'pet': 'Max',
        'date': 'October 14',
        'hasReminder': true,
      },
      {
        'name': 'Vaccination Day',
        'pet': 'Luna',
        'date': 'May 2',
        'hasReminder': true,
      },
    ];

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
                style: const TextStyle(
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
          child: Container(
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
                      eventName: event['name'] as String,
                      petName: event['pet'] as String,
                      date: event['date'] as String,
                      hasReminder: event['hasReminder'] as bool,
                      isGrouped: true,
                      onTap: () => _showUnavailableMessage(),
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

  bool _hasOverdueVaccines() {
    // TODO: Implement logic to check if there are overdue vaccines
    return true; // Mock data shows overdue vaccines
  }
}
