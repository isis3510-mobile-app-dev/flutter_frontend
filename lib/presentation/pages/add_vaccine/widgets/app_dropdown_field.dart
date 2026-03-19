import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';

class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

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
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          icon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.arrow_drop_down, color: hintColor),
          ),
          dropdownColor: fillColor,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                ),
              )
              .toList(growable: false),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: _dropdownBorder(borderColor),
            focusedBorder: _focusedDropdownBorder,
            disabledBorder: _dropdownBorder(borderColor),
            errorBorder: _errorDropdownBorder,
            focusedErrorBorder: _errorDropdownBorder,
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _dropdownBorder(Color color) => OutlineInputBorder(
  borderRadius: const BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: color, width: 1.5),
);

const OutlineInputBorder _focusedDropdownBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
);

const OutlineInputBorder _errorDropdownBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.error, width: 1.5),
);
