import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.titleMedium,
        ),
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
          style: context.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
            suffixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(icon),
                  ),
            suffixIconColor: AppColors.grey500,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: _border,
            focusedBorder: _border,
            disabledBorder: _border,
          ),
        ),
      ],
    );
  }
}

const OutlineInputBorder _border = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(
    color: AppColors.grey500,
    width: 1.5,
  ),
);
