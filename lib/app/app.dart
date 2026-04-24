import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/services/app_preferences_service.dart';
import '../core/theme/app_theme.dart';
import '../core/telemetry/screen_time_observer.dart';
import 'routes.dart';
import 'theme_controller.dart';

/// Root widget of the application.
/// Responsible for global configuration: theme, routing, and localization.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppPreferencesService _appPreferencesService;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _appPreferencesService = AppPreferencesService();
    _themeController = ThemeController(
      preferencesService: _appPreferencesService,
    );
    _themeController.initialize();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'PetCare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeController.themeMode,
            initialRoute: Routes.authGate,
            navigatorObservers: [ScreenTimeObserver()],
            onGenerateRoute: Routes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
