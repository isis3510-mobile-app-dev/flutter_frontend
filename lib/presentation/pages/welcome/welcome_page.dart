
import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/welcome/widgets/welcome_background_circles.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

import 'welcome_step_model.dart';
import 'widgets/welcome_controls.dart';
import 'widgets/welcome_progress_dot.dart';
import 'widgets/welcome_step_content.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();

}


class _WelcomePageState extends State<WelcomePage> {
  int _currentIndex = 0;

  final List<WelcomeStepModel> _steps = [
    WelcomeStepModel(
      title: AppStrings.welcomeFirstTitle,
      description: AppStrings.welcomeFirstDescription,
      backgroundColor: AppColors.welcomeFirstBackground,
      imagePath: 'assets/images/welcome1.png',
    ),
    WelcomeStepModel(
      title: AppStrings.welcomeSecondTitle,
      description: AppStrings.welcomeSecondDescription,
      backgroundColor: AppColors.welcomeSecondBackground,
      imagePath: 'assets/images/welcome2.png',
    ),
    WelcomeStepModel(
      title: AppStrings.welcomeThirdTitle,
      description: AppStrings.welcomeThirdDescription,
      backgroundColor: AppColors.welcomeThirdBackground,
      imagePath: 'assets/images/welcome3.png',
    ),
  ];

  void _next() {
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      Navigator.of(context).pushNamed(Routes.auth);
    }
  }

  void _back() => setState(() => _currentIndex--);

  void _skip() {
    Navigator.of(context).pushNamed(Routes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            step.backgroundColor[0],
            step.backgroundColor[1],
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          WelcomeBackgroundCircles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10), 
              child: Column(
                children: [
                  WelcomeControls(
                    currentIndex: _currentIndex,
                    totalSteps: _steps.length,
                    onBack: _currentIndex > 0 ? _back : null,
                    onSkip: _skip,
                  ),
                  Expanded(
                    child: WelcomeStepContent(step: step),
                  ),
                  const SizedBox(height: 32),
                  WelcomeProgressDots(
                    total: _steps.length,
                    currentIndex: _currentIndex,
                  ),
                  const SizedBox(height: 32),
                  FullWidthButton(
                    text: _currentIndex < _steps.length -1 ? AppStrings.semanticContinueButton : AppStrings.semanticGetStartedButton, 
                    onPressed: _next,
                    height: 57,
                    backgroundColor: Color(0x24FFFFFF),
                    borderColor: Color(0x99FFFFFF),
                    textColor: Colors.white,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.welcomeAlreadyHaveAccount, 
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      TextButton(
                        onPressed: _skip, 
                        child: Text(
                          AppStrings.semanticSignInButton,
                          style: context.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          ),
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}