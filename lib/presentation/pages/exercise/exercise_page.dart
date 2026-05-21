import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_dimensions.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise tracker')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets_outlined, size: 56),
              const SizedBox(height: AppDimensions.spaceM),
              const Text(
                'Exercise tracking now lives inside each pet profile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.pets),
                child: const Text('Open pets'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
