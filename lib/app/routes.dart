import 'package:flutter/material.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_page.dart';
import 'package:flutter_frontend/presentation/pages/records/records_page.dart';
import 'package:flutter_frontend/presentation/pages/welcome/welcome_page.dart';
import '../presentation/pages/home/home_page.dart';

/// Centralized route definitions for the app.
/// Using named routes makes navigation cleaner and easier to maintain.
/// Add every new page here — avoid inline MaterialPageRoute calls.
class Routes {
  Routes._(); // Prevents instantiation

  // Route name constants — use these instead of raw strings throughout the app
  static const String home = '/';
  static const String detail = '/detail';
  static const String welcomePage = '/welcome';
  static const String addVaccine = '/add-vaccine';
  static const String records = '/records';

  /// Maps route names to their corresponding page widgets.
  /// Called automatically by MaterialApp when navigating.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomePage:
        return _buildRoute(const WelcomePage(), settings);

      case home:
        return _buildRoute(const HomePage(), settings);

      case addVaccine:
        return _buildRoute(const AddVaccinePage(), settings);

      case records:
        return _buildRoute(const RecordsPage(), settings);

      case detail:
        // Example of passing arguments to a route
        // final args = settings.arguments as MyArguments;
        // return _buildRoute(DetailPage(args: args), settings);
        return null;

      default:
        // Fallback for unknown routes
        return _buildRoute(const HomePage(), settings);
    }
  }

  /// Helper to build a consistent page transition for all routes.
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}