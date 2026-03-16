import 'package:flutter/material.dart';
import '../presentation/pages/auth/auth_gate.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

/// Root widget of the application.
/// Responsible for global configuration: theme, routing, and localization.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthGate(),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}