import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_strings.dart';
import '../records/records_page.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';
import '../../../shared/widgets/quick_actions_fab.dart';

/// Home page of the application.
/// This is a placeholder — replace with your actual home screen content.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _replaceWithoutAnimation(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      return;
    }

    if (index == 2) {
      _replaceWithoutAnimation(const RecordsPage());
      return;
    }

    setState(() => _currentIndex = index);
  }

  void _goToAddVaccine() {
    Navigator.of(context).pushNamed(Routes.addVaccine);
  }

  void _goToAddEvent() {
    Navigator.of(context).pushNamed(Routes.addEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      body: const Center(child: Text(AppStrings.homeWelcome)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: () {},
        onAddVaccine: _goToAddVaccine,
        onAddEvent: _goToAddEvent,
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}
