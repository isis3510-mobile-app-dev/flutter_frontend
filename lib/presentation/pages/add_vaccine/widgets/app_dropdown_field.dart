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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          icon: const Icon(Icons.arrow_drop_down),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: _dropdownBorder,
            focusedBorder: _dropdownBorder,
            disabledBorder: _dropdownBorder,
          ),
        ),
      ],
    );
  }
}

const OutlineInputBorder _dropdownBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  borderSide: BorderSide(color: AppColors.grey500, width: 1.5),
);
