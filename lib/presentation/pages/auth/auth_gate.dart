import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
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
  final GlobalKey<NavigatorState> _unauthenticatedNavigatorKey =
      GlobalKey<NavigatorState>();

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

        return Navigator(
          key: _unauthenticatedNavigatorKey,
          initialRoute: Routes.welcomePage,
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
  }
}