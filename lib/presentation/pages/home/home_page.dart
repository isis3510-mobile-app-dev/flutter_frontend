import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_strings.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      body: const Center(child: Text(AppStrings.homeWelcome)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: () => Navigator.pushNamed(context, Routes.addPet),
        onAddVaccine: () {},
        onAddEvent: () {},
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushNamed(context, Routes.pets);
            return;
          }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
