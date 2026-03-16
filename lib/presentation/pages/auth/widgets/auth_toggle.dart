import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class AuthToggle extends StatelessWidget {
  const AuthToggle({
    super.key,
    required this.isSignInSelected,
    required this.signInLabel,
    required this.createAccountLabel,
    required this.onChanged,
  });

  final bool isSignInSelected;
  final String signInLabel;
  final String createAccountLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.segmentedControlHeight,
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceXS),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: signInLabel,
              selected: isSignInSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: createAccountLabel,
              selected: !isSignInSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondary : AppColors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.primary : AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
