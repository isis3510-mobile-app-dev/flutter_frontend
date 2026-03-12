import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/petcare_bottom_nav_bar.dart';

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
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
      ),
      body: const Center(
        child: Text(AppStrings.homeWelcome),
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}