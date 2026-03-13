import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class Stepper extends StatelessWidget {
  const Stepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.grey300,
    this.lineColor = AppColors.grey300,
    this.activeTextColor = AppColors.primary,
    this.inactiveTextColor = AppColors.grey700,
  }) : assert(steps.length > 1, 'Stepper needs at least 2 steps.'),
       assert(currentStep >= 0, 'currentStep must be >= 0.'),
       assert(currentStep < steps.length, 'currentStep is out of range.');

  final List<String> steps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final Color lineColor;
  final Color activeTextColor;
  final Color inactiveTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: i <= currentStep ? activeColor : lineColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                _StepCircle(
                  index: i + 1,
                  isActive: i <= currentStep,
                  done: i < currentStep,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  steps[i],
                  textAlign: i==0 ? TextAlign.left : i == steps.length - 1 ? TextAlign.right : TextAlign.center,
                  style: TextStyle(
                    fontSize: context.textTheme.bodySmall?.fontSize,
                    fontWeight: FontWeight.w500,
                    color: i == currentStep ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isActive,
    required this.done,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int index;
  final bool isActive;
  final bool done;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: done
      ? const Icon(Icons.check, color: Colors.white, size: 18)
      : Text(
          '$index',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.onPrimary : AppColors.onSurface,
        ),
      ),
    );
  }
}
