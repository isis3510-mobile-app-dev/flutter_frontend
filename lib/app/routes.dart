import 'package:flutter/material.dart';
import '../presentation/pages/welcome/welcome_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/pets/add_pet/add_pet_screen.dart';
import '../presentation/pages/pets/pets_page.dart';

/// Centralized route definitions for the app.
/// Using named routes makes navigation cleaner and easier to maintain.
/// Add every new page here — avoid inline MaterialPageRoute calls.
class Routes {
  Routes._(); // Prevents instantiation

  // Route name constants — use these instead of raw strings throughout the app
  static const String home = '/';
  static const String welcomePage = '/welcome';
  static const String pets = '/pets';
  static const String addPet = '/pets/add';

  /// Maps route names to their corresponding page widgets.
  /// Called automatically by MaterialApp when navigating.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomePage:
        return _buildRoute(const WelcomePage(), settings);

      case home:
        return _buildRoute(const HomePage(), settings);

      case pets:
        return _buildRoute(const PetsPage(), settings);

      case addPet:
        return _buildRoute(const AddPetScreen(), settings);

      default:
        // Fallback for unknown routes
        return _buildRoute(const HomePage(), settings);
    }
  }

  /// Helper to build a consistent page transition for all routes.
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
