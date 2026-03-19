import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.secondaryDark : AppColors.secondary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;
    final hintColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
        : AppColors.grey500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelLarge),
        const SizedBox(height: AppDimensions.spaceS),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && obscureText,
          style: context.textTheme.bodyMedium?.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.textTheme.bodyMedium?.copyWith(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceM,
            ),
            enabledBorder: _fieldBorder(borderColor),
            focusedBorder: _focusedFieldBorder,
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    color: hintColor,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
  borderRadius: const BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
  borderSide: BorderSide(color: color, width: AppDimensions.strokeThin),
);

const OutlineInputBorder _focusedFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
  borderSide: BorderSide(
    color: AppColors.primary,
    width: AppDimensions.strokeThin,
  ),
);
