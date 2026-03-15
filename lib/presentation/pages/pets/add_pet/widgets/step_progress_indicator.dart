import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < currentStep;

              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isCompleted
                      ? AppColors.bottomNavActive
                      : (isDark
                            ? AppColors.addPetStepInactiveLineDark
                            : AppColors.grey300),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return _StepCircle(
              index: stepIndex,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );
          }),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          children: List.generate(totalSteps, (stepIndex) {
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return Expanded(
              child: Align(
                alignment: stepIndex == 0
                    ? Alignment.centerLeft
                    : (stepIndex == totalSteps - 1
                          ? Alignment.centerRight
                          : Alignment.center),
                child: Text(
                  labels[stepIndex],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCompleted || isCurrent
                        ? AppColors.bottomNavActive
                        : AppColors.grey500,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int index;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.bottomNavActive,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }

    if (isCurrent) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.bottomNavActive,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.addPetStepInactiveCircleDark
            : AppColors.addPetStepInactiveCircle,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.grey500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
