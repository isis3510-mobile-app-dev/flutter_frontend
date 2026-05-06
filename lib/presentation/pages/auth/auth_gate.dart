import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/services/app_preferences_service.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/presentation/pages/home/home_page.dart';
import 'package:flutter_frontend/presentation/pages/welcome/welcome_page.dart';

import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final AppPreferencesService _preferencesService = AppPreferencesService();
  final GlobalKey<NavigatorState> _unauthenticatedNavigatorKey =
      GlobalKey<NavigatorState>();
  late final Future<String> _initialUnauthenticatedRoute;

  @override
  void initState() {
    super.initState();
    _initialUnauthenticatedRoute = _resolveInitialUnauthenticatedRoute();
  }

  Future<String> _resolveInitialUnauthenticatedRoute() async {
    final hasSeenWelcome = await _preferencesService.getHasSeenWelcome();
    return hasSeenWelcome ? Routes.auth : Routes.welcomePage;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return FutureBuilder<String>(
          future: _initialUnauthenticatedRoute,
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Navigator(
              key: _unauthenticatedNavigatorKey,
              initialRoute: routeSnapshot.data ?? Routes.welcomePage,
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case Routes.auth:
                    return MaterialPageRoute<void>(
                      builder: (_) => const AuthPage(),
                      settings: settings,
                    );
                  case Routes.welcomePage:
                  default:
                    return MaterialPageRoute<void>(
                      builder: (_) => const WelcomePage(),
                      settings: settings,
                    );
                }
              },
            );
          },
        );
      },
    );
  }
}
