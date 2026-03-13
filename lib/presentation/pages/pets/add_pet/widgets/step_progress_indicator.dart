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

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 22),
              color: isCompleted
                  ? AppColors.bottomNavActive
                  : (isDark ? const Color(0xFF3A3940) : AppColors.grey300),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return SizedBox(
          width: 88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepCircle(
                index: stepIndex,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                labels[stepIndex],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCurrent || isCompleted
                      ? (isDark ? AppColors.onSurfaceDark : AppColors.grey900)
                      : AppColors.grey500,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
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
    if (isCompleted) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.bottomNavActive,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    }

    if (isCurrent) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.bottomNavActive,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey300),
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.grey500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
