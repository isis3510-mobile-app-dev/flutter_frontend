import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    required this.hintText,
    this.icon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.controller,
    this.onTap,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final IconData? icon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.secondaryDark : AppColors.secondary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey500;
    final hintColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
        : AppColors.grey500;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.textTheme.titleMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: context.textTheme.bodyMedium?.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.textTheme.bodyMedium?.copyWith(color: hintColor),
            filled: true,
            fillColor: fillColor,
            suffixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(icon),
                  ),
            suffixIconColor: hintColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: _border(borderColor),
            focusedBorder: _focusedBorder,
            disabledBorder: _border(borderColor),
            errorBorder: _errorBorder,
            focusedErrorBorder: _errorBorder,
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: const BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: color, width: 1.5),
);

const OutlineInputBorder _focusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
);

const OutlineInputBorder _errorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.error, width: 1.5),
);
