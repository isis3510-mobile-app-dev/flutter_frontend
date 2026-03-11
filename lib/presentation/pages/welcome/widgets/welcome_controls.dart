import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';

class WelcomeControls extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const WelcomeControls({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Back button — invisible on first step to preserve layout
          Opacity(
            opacity: onBack != null ? 1.0 : 0.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),
          ),
          Expanded(child: Container(),),
          // Skip button — hidden on last step
          if (currentIndex < totalSteps - 1)
            TextButton(
              onPressed: onSkip,
              child: const Text(
                AppStrings.semanticSkipButton,
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            // Placeholder to keep back button aligned when skip disappears
            const SizedBox(width: 48),
        ],
      );
  }
}