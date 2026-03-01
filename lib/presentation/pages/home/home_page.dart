import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

/// Home page of the application.
/// This is a placeholder — replace with your actual home screen content.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
      ),
      body: const Center(
        child: Text(AppStrings.homeWelcome),
      ),
    );
  }
}