import 'package:flutter/material.dart';
import 'package:flutter_frontend/presentation/pages/add_event/add_event_page.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_args.dart';
import 'package:flutter_frontend/presentation/pages/add_vaccine/add_vaccine_page.dart';
import 'package:flutter_frontend/presentation/pages/nfc/nfc_page.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/presentation/pages/records/detail/detail_page.dart';
import '../presentation/pages/auth/auth_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/pets/models/pet_ui_model.dart';
import '../presentation/pages/pets/add_pet/add_pet_screen.dart';
import '../presentation/pages/pets/pet_detail/pet_detail_screen.dart';
import '../presentation/pages/pets/pets_page.dart';
import '../presentation/pages/profile/edit_profile_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/records/records_page.dart';
import '../presentation/pages/welcome/welcome_page.dart';

/// Centralized route definitions for the app.
/// Using named routes makes navigation cleaner and easier to maintain.
/// Add every new page here — avoid inline MaterialPageRoute calls.
class Routes {
  Routes._(); // Prevents instantiation

  // Route name constants — use these instead of raw strings throughout the app
  static const String home = '/';
  static const String auth = '/auth';
  static const String welcomePage = '/welcome';
  static const String pets = '/pets';
  static const String addPet = '/pets/add';
  static const String petDetail = '/pets/detail';
  static const String addVaccine = '/vaccines/add';
  static const String vaccineDetail = 'vaccine/detail';
  static const String addEvent = '/event/add';
  static const String eventDetail = 'event/detail';
  static const String nfc = '/nfc';
  static const String records = '/records';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  static const int recordsFilterAll = 0;
  static const int recordsFilterVaccines = 1;
  static const int recordsFilterEvents = 2;

  /// Maps route names to their corresponding page widgets.
  /// Called automatically by MaterialApp when navigating.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return _buildRoute(const AuthPage(), settings);

      case welcomePage:
        return _buildRoute(const WelcomePage(), settings);

      case home:
        return _buildRoute(const HomePage(), settings);

      case pets:
        return _buildRoute(const PetsPage(), settings);

      case addPet:
        return _buildRoute(const AddPetScreen(), settings);

      case petDetail:
        return _buildPetDetailRoute(settings);

      case addVaccine:
        final args = settings.arguments;
        if (args is AddVaccineArgs) {
          return _buildRoute(AddVaccinePage(prefill: args), settings);
        }
        return _buildRoute(const AddVaccinePage(), settings);

      case nfc:
        return _buildRoute(const NfcPage(), settings);

      case records:
        return _buildRecordsRoute(settings);

      case profile:
        return _buildRoute(const ProfilePage(), settings);
      case profileEdit:
        return _buildEditProfileRoute(settings);
      case addEvent:
        return _buildRoute(const AddEventPage(), settings);

      case vaccineDetail:
        return _buildRoute(const DetailPage(type: 'vaccine'), settings);

      case eventDetail:
        return _buildRoute(const DetailPage(type: 'event'), settings);

      default:
        // Fallback for unknown routes
        return _buildRoute(const HomePage(), settings);
    }
  }

  /// Helper to build a consistent page transition for all routes.
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static MaterialPageRoute _buildRecordsRoute(RouteSettings settings) {
    final argument = settings.arguments;
    final initialFilterIndex = argument is int &&
            argument >= recordsFilterAll &&
            argument <= recordsFilterEvents
        ? argument
        : recordsFilterAll;

    return _buildRoute(
      RecordsPage(initialFilterIndex: initialFilterIndex),
      settings,
    );
  }

  static MaterialPageRoute _buildPetDetailRoute(RouteSettings settings) {
    final pet = settings.arguments;

    if (pet is! PetUiModel) {
      return _buildRoute(const PetsPage(), settings);
    }

    return _buildRoute(PetDetailScreen(pet: pet), settings);
  }

  static MaterialPageRoute _buildEditProfileRoute(RouteSettings settings) {
    final profile = settings.arguments;

    if (profile is! UserProfile) {
      return _buildRoute(const ProfilePage(), settings);
    }

    return _buildRoute(EditProfilePage(profile: profile), settings);
  }

  static String? bottomNavRouteForIndex(int index) {
    return switch (index) {
      0 => home,
      1 => pets,
      2 => records,

      4 => profile,
      _ => null,
    };
  }
}
